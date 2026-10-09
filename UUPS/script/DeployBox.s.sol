//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Script} from "forge-std/Script.sol";
import {BoxV1} from "../src/BoxV1.sol";

/*
 Steps of deployment: 
   Deploy BoxV1
   Get an address
   Deploy Proxy with BoxV1 address
   Verify that everything works
   Deploy BoxV2
   Point Proxy to BoxV2
 */
contract DeployBox is Script {
    function run() external returns (address) {
        address proxy = deployBox();
        return proxy;
    }

    /**
     * @notice deploys the proxy contract
     * @return address : address of the proxy contract
     */
    function deployBox() public returns (address) {
        vm.startBroadcast();
        BoxV1 box = new BoxV1(); // Implementation
        ERC1967Proxy proxy = new ERC1967Proxy(address(box), "");
        BoxV1(address(proxy)).initialize();
        vm.stopBroadcast();
        return address(proxy);
    }
}
