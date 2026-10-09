//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {LuxureToken} from "../src/LuxureToken.sol";

contract DeployLuxure is Script {
    function run() external returns (LuxureToken) {
        vm.startBroadcast();
        LuxureToken dluxure = new LuxureToken(500);
        vm.stopBroadcast();
        return dluxure;
    }
}
