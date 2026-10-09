//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BengalToken} from "../src/BengalToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol"; // If using foundry-devops
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    /*
    What we need for effective testing :
    1. A valid Merkle root: This is the single hash stored in the smart contract that represents 
    the entirety of the airdrop distribution data.
    2. A list of addresses and their corresponding airdrop amounts: This data forms the "leaves" of 
    the Merkle tree.
    3. A Merkle proof for each specific address/amount pair: This proof allows an individual user to 
    demonstrate that their address and amount are part of the Merkle tree, without revealing the entire dataset.
    */

    // Inside MerkleAirdropTest contract
    MerkleAirdrop public airdrop;
    BengalToken public token;
    DeployMerkleAirdrop deployer;

    // It will be updated later in the process
    bytes32 public ROOT = 0xb7c59efa89f34e7107284e304a606e70baea4abaee71632cf75e311fad041968;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18; // Example claim amount for the test user
    uint256 public AMOUNT_TO_SEND; // Total tokens to fund the airdrop contract
    address gasPayer;

    bytes32 proofOne = 0x0fd7cf30139bcce6f17499702bf9b3114ae9e066b51ba2c53abdf7b62966e00a;
    bytes32 proofTwo = 0x0d6f4c7c1c21e8a0e0349bedda51d2d02e1ec75b551d97a999d3edbafa5a1e2f;
    bytes32[] public PROOF = [proofOne, proofTwo];

    address user;
    uint256 userPrivKey; // Private key for the test user

    function setUp() public {
        // deploy to another chain if not not on zksync
        if (!isZkSyncChain()) {
            deployer = new DeployMerkleAirdrop();
            (token, airdrop) = deployer.run();
        } else {
            // deploy token contract
            token = new BengalToken();
            //create a user with private key , address
            (user, userPrivKey) = makeAddrAndKey("userAddress");
            gasPayer = makeAddr("gas-payer");
            // let's deploy the air drop contract
            airdrop = new MerkleAirdrop(ROOT, token);
            //mint the user the amount * 4
            token.mint(address(this), AMOUNT_TO_CLAIM * 4);
            // now let's transfer the tokens from owner to airdrop contract
            require(token.transfer(address(airdrop), AMOUNT_TO_CLAIM * 4),"Transfer Failed");
            console.log("User: ", user);
        }
    }

    // first test
    function testUserCanClaimForReceipient() public {
        // get receipient balance before
        uint256 balanceBefore = token.balanceOf(user);
        //get message hash
        bytes32 digest = airdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        // let user signs the message with their private key
        (uint8 v, bytes32 s, bytes32 r) = vm.sign(userPrivKey, digest);
        // let the gas payer claim for user
        vm.deal(gasPayer, 200 ether);
        vm.prank(gasPayer);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, s, r);

        // validate receiptients amount after  airdrop
        uint256 balanceAfter = token.balanceOf(user);
        assertGe(balanceAfter, balanceBefore, "User balance dit not increase in value");
    }
}
