// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import {Script} from "forge-std/Script.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
// import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/TokenAdminRegistry.sol";



contract TokenAndPoolDeployer is Script {
    
    // Implementation for RebaseToken and RebaseTokenPool deployment will be added here.
    function run() public returns (RebaseToken token, RebaseTokenPool pool) {
        CCIPLocalSimulatorFork ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
       Register.NetworkDetails memory networkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        // Deployment and configuration logic
         vm.startBroadcast();
          token = new RebaseToken();
          pool = new RebaseTokenPool(
            IERC20(address(token)),            // The deployed token address
            new address[](0),                  // Empty allowlist
            networkDetails.rmnProxyAddress,    // RMN Proxy address from simulator
            networkDetails.routerAddress       // Router address from simulator
        );

        token.grantMintAndBurnRole(address(pool));
        //------------- CCIP CONFIGURATIONS  -----------------------
        //register admin 
        RegistryModuleOwnerCustom(networkDetails.registryModuleOwnerCustomAddress)
        .registerAdminViaOwner(address(token));
        //accept admin role 
         TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress)
        .acceptAdminRole(address(token));
        //set pool 
         TokenAdminRegistry(networkDetails.tokenAdminRegistryAddress)
        .setPool(address(token), address(pool));
        vm.stopBroadcast();

    }
}


contract VaultDeployer is Script {
    // Implementation for Vault deployment will be detailed below.
    function run(address _rebaseToken) public returns (Vault vault) {
        vm.startBroadcast();
        vault = new Vault(IRebaseToken(_rebaseToken)); // 'vault' is now assigned to the return variable
        IRebaseToken(_rebaseToken).grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
        // Foundry implicitly returns the 'vault' instance here
    }
}