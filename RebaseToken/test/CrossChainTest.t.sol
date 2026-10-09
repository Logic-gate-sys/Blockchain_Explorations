//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
// Import your project-specific contracts
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
// Import the Chainlink Local simulator
import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/TokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/TokenAdminRegistry/TokenAdminRegistry.sol";
import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";

contract CrossChainTest is Test {
    uint256 sepoliaFork;
    uint256 arbFork;
    CCIPLocalSimulatorFork ccipLocalSimulatorFork;
    RebaseToken sepoliaToken;
    RebaseToken arbToken;
    Vault vault;
    address owner;
    // for pool
    RebaseTokenPool sepoliaPool;
    RebaseTokenPool arbPool;
    //network details
    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbNetworkDetails;

    //setup
    function setUp() public {
        // make address
        owner = makeAddr("owner");
        //craate and select the source fork
        sepoliaFork = vm.createSelectFork("sepolia");
        // create destination fork
        arbFork = vm.createFork("arb-sepolia");
        // deploy cciplocalsimultorfork
        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        // persist address of the simulator so that source and destination forks interact with the same simulator instance
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // simulate user deploying on sepolia chain
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken("RebaseToken", "RBT");
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        vm.stopPrank();

        // switch fork and deploy rebase token to Arbitrum
        vm.createSelectFork(arbFork);
        vm.startPrank(owner);
        arbToken = new RebaseToken("RebaseToken", "RBT");
        vm.stopPrank();

        //get Sepolia network details
        vm.selectFork(sepoliaFork);
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        //get Abitrum network details
        vm.selectFork(arbFork);
        arbNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        //--------------- deploy pools -------------------------

        // deploy sepolia pool
        vm.selectFork(sepoliaFork);
        sepoliaPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)),
            address[](0),
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );
        // deploy abitrum pool
        vm.selectFork(arbFork);
        arbPool = new RebaseToken(
            IERC20(address(arbToken)), address[](0), arbNetworkDetails.rmnProxyAddress, arbNetworkDetails.routerAddress
        );

        // ----------------- grant acess -----------------------
        // sepolia chain
        vm.selectFork(sepoliaFork);
        vm.startPrank(owner);
        sepoliaToken.grandMintAndBurnRole(address(vault));
        sepoliaToken.grandMintAndBurnRole(address(sepoliaPool));
        vm.stopPrank();

        // abitrum chain
        vm.selectFork(arbFork);
        vm.startPrank(owner);
        arbToken.grandMintAndBurnRole(address(arbPool));
        vm.stopPrank();

        //---------- Claiming Admin roles for CCIP  ---------------
        //sepolia
        vm.selectFork(sepoliaFork);
        vm.startPrank(owner);
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(sepoliaToken)
        );
        vm.stopPrank();

        // arbitrum
        vm.selectFork(arbFork);
        vm.startPrank(owner);
        RegistryModuleOwnerCustom(arbNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(arbToken)
        );
        vm.stopPrank();

        //----------- Accepting Token Administrator Roles for CCIP -------------

        // On Sepolia fork
        vm.selectFork(sepoliaFork);
        vm.startPrank(owner);
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        vm.stopPrank();

        // on Aribitrum fork
        vm.selectFork(arbFork);
        vm.startPrank(owner);
        TokenAdminRegistry(arbNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbToken));
        vm.stopPrank();

        //-------------- Linking Tokens to Their Respective Pools ----------------
        // On Sepolia fork
        vm.selectFork(sepoliaFork);
        vm.startPrank(owner);
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(sepoliaToken), address(sepoliaPool)
        );
        vm.stopPrank();
        // On arbitrum fork
        vm.selectFork(arbFork);
        vm.startPrank(owner);
        TokenAdminRegistry(arbNetworkDetails.tokenAdminRegistryAddress).setPool(address(arbToken), address(arbPool));
        vm.stopPrank();

        //----------------- activate cross-chain communication -----------------------
        // Configure Sepolia Pool to interact with Arbitrum Sepolia Pool
        configureTokenPool(
            sepoliaFork, // Local chain: Sepolia
            address(sepoliaPool), // Local pool: Sepolia's TokenPool
            arbSepoliaNetworkDetails.chainSelector, // Remote chain selector: Arbitrum Sepolia's
            address(arbSepoliaPool), // Remote pool address: Arbitrum Sepolia's TokenPool
            address(arbSepoliaToken) // Remote token address: Arbitrum Sepolia's Token
        );

        // configure arbitrum to communicate with sepolia
        configureTokenPool(
            arbFork, address(arbPool), sepoliaNetworkDetails.chainSelector, address(sepoliaPool), address(sepoliaToken)
        );
    }

    // Configure Token pool
    function configureTokenPool(
        uint256 forkId, // The fork ID of the local chain
        address localPoolAddress, // Address of the pool being configured
        uint64 remoteChainSelector, // Chain selector of the remote chain
        address remotePoolAddress, // Address of the pool on the remote chain
        address remoteTokenAddress // Address of the token on the remote chain
    ) public {
        // ---------- Select the correct fork (local chain context)-------------
        vm.selectFork(forkId);

        //------------ arguments for chain updates ----------------------------
        //empty chain selectors to remove address: we are only adding not removing
        uint64[] memory remoteChainSelectorsToRemove = new uint64[](0);

        // length 1 chains to add array
        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);

        //abi-encode remote pool addresses
        bytes[] memory remotePoolAddressesBytesArray = new bytes[](1);
        remotePoolAddressesBytesArray[0] = abi.encode(remotePoolAddress);

        //populate chain to update struct
        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            remotePoolAddresses: abi.encode(remotePoolAddressesBytesArray), // ABI-encode the array of bytes
            remoteTokenAddress: abi.encode(remoteTokenAddress),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });

        // ------------- apply chain updatas as the owner -----------------------------------
        vm.prank(owner); // The 'owner' variable should be the deployer/owner of the localPoolAddress
        TokenPool(localPoolAddress).applyChainUpdates(remoteChainSelectorsToRemove, chainsToAdd);
    }

    // helper function for bridging
    function bridgeTokens(
        uint256 amountToBridge,
        uint256 localFork, // Source chain fork ID
        uint256 remoteFork, // Destination chain fork ID
        Register.NetworkDetails memory localNetworkDetails, // Struct with source chain info
        Register.NetworkDetails memory remoteNetworkDetails, // Struct with dest. chain info
        RebaseToken localToken, // Source token contract instance
        RebaseToken remoteToken // Destination token contract instance
    ) public {
        // on local chain
        vm.selectFork(localFork);
        //token amounts array
        Client.EVMTokenAmount[] memory tokenAmount = new Client.EVMTokenAmount[](1);
        tokenAmount[0] = Client.EVMTokenAmount({token: address(localToken), amount: amountToBridge});
        //---------- construct EVM2AnyMessage --------------
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(user),
            add: "",
            tokenAmount: tokenAmount,
            feeToken: localNetworkDetails.linkAddress,
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 100_000}))
        });
        // ------------ Get the CCIP fee incurred ------------------
        uint256 fee =
            IRouterClient(localNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector, message);

        // --------- Funding Fees ---------------------------------
        //fund use with LINK
        cciplocalsimultorfork.requestLinkFromFaucet(user, fee);

        // ------------- Approve source chain's router to spend  LINK for CCIP fee ------------------
        vm.prank(user);
        IERC20(localNetworkDetails.linkAddress).approve(localNetworkDetails.routerAddress, fee);
        // ------------- Approve the source chain router contract to transfer the token being bridge  ---------------------------------
        IERC20(localToken).approve(localNetworkDetails.routerAddress, amountToBridge);

        // ------------------------ sending message ----------------------------------------
        uint256 localBalanceBefore = localToken.balanceOf(user);
        vm.prank(user);
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(remoteNetworkDetails.chainSelector, message);
        uint256 localBalanceAfter = localToken.balanceOf(user);
        assertEq(localBalanceAfter, localBalanceBefore - amountToBridge);
        //get local interest rate
        uint256 localInterestRate = localToken.getUserInterestRate(user);
        // --------------- Simulating cross-chain message propagation : since message does not automatical propage on localchains---------------------
        vm.warp(block.timestamp + 20 minutes);
        uint256 remoteBalanceBefore = remoteToken.balanceOf(user);
        //process message on remote chain
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork);
        uint256 remoteBalanceAfter = remoteToken.balanceOf(user);
        assertEq(remoteBalanceBefore + amountToBridge, remoteBalanceAfter);

        // remote interest rate
        uint256 remoteInterestRate = remoteToken.getInterestRate(user);
        assertEq(localInterestRate, remoteInterestRate);
    }


    //testing 
    function testBridgeAllTokens() public {
    uint256 DEPOSIT_AMOUNT = 1e5; // Using a small, fixed amount for clarity

    // 1. Deposit into Vault on Sepolia
    vm.selectFork(sepoliaFork);
    vm.deal(user, DEPOSIT_AMOUNT); // Give user some ETH to deposit

    vm.prank(user);
    // To send ETH (msg.value) with a contract call in Foundry:
    // Cast contract instance to address, then to payable, then back to contract type.
    Vault(payable(address(vault))).deposit{value: DEPOSIT_AMOUNT}();

    assertEq(sepoliaToken.balanceOf(user), DEPOSIT_AMOUNT, "User Sepolia token balance after deposit incorrect");

    // 2. Bridge Tokens: Sepolia -> Arbitrum Sepolia
    bridgeTokens(
        sepoliaFork,
        arbSepoliaFork,
        user,
        sepoliaToken,
        arbSepoliaToken,
        DEPOSIT_AMOUNT,
        sepoliaNetworkDetails,
        arbSepoliaNetworkDetails
    );
    // Assertions for this step are within bridgeTokens​
    // 3. Bridge All Tokens Back: Arbitrum Sepolia -> Sepolia
    vm.selectFork(arbSepoliaFork);
    vm.warp(block.timestamp + 20 minutes); // Advance time on Arbitrum Sepolia before bridging back​
    uint256 arbBalanceToBridgeBack = arbSepoliaToken.balanceOf(user);
    assertTrue(arbBalanceToBridgeBack > 0, "User Arbitrum balance should be non-zero before bridging back");
    bridgeTokens(
        arbSepoliaFork,
        sepoliaFork,
        user,
        arbSepoliaToken,
        sepoliaToken,
        arbBalanceToBridgeBack,
        arbSepoliaNetworkDetails,
        sepoliaNetworkDetails
    );

    // Final state check: User on Sepolia should have their initial deposit back
    // (minus any very small precision differences if applicable to tokenomics, or fees not covered by faucet)
    vm.selectFork(sepoliaFork);
    // Note: Exact final balance might depend on tokenomics if any fees were burnt from principal.
    // For this example, assume full amount returns.
    assertEq(sepoliaToken.balanceOf(user), DEPOSIT_AMOUNT, "User Sepolia token balance after bridging back incorrect");
}

/*
Additional test : 
Bridging partial amounts of tokens.

Multiple consecutive bridge operations in both directions.

Testing failure cases (e.g., insufficient fees, invalid receiver).

Interactions with different users.
 */
}
