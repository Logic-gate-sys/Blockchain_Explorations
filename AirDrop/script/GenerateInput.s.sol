//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

/*
 ----------- User input should be a json file of the form :
 {
  "types": [...],
  "count": ...,
  "values": {
    "0": {"0": "...", "1": "..."},
    "1": {"0": "...", "1": "..."},
    ...
  }
}
 */

contract GenerateInput is Script {
    // file path
    string constant FILE_PATH = "script/target/input.json";

    // funciton to generat the require input
    function run() public {
        //contstruct types array
        string[] memory types = new string[](2);
        types[0] = "address"; // address
        types[1] = "uint"; // amount

        // sample amount
        uint256 amount = 2000 * 1e18;
        address[] memory whitelist = new address[](5);
        whitelist[0] = 0x0e466e7519A469f20168796a0807b758a2339791;
        whitelist[1] = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B; // Example addresses
        whitelist[2] = 0x1Db3439a222C519ab44bb1144fC28167b4Fa6EE6;
        whitelist[3] = 0x0e466e7519A469f20168796a0807b758a2339791;
        whitelist[4] = 0x62eF26c9C3696Dc6eCB4845972F1C2F2aDA1521f;

        // create json
        string memory json = createJSON(types, whitelist, amount);
        // write json to targe location
        vm.writeFile(FILE_PATH, json);
        console.log("Input file created successfully");
    }

    function createJSON(string[] memory types, address[] memory whitelist, uint256 amount)
        internal
        pure
        returns (string memory)
    {
        string memory json = "{";
        // Add types
        json = string.concat(json, "\"types\": [");
        for (uint256 i = 0; i < types.length; i++) {
            json = string.concat(json, "\"", types[i], "\"");
            if (i < types.length - 1) {
                json = string.concat(json, ", ");
            }
        }
        json = string.concat(json, "], ");

        // Add count
        json = string.concat(json, "\"count\": ", vm.toString(whitelist.length), ", ");

        // Add values
        json = string.concat(json, "\"values\": {");
        for (uint256 i = 0; i < whitelist.length; i++) {
            json = string.concat(
                json,
                "\"",
                vm.toString(i),
                "\": {",
                "\"0\": \"",
                vm.toString(whitelist[i]),
                "\", ",
                "\"1\": \"",
                vm.toString(amount),
                "\"}"
            );
            if (i < whitelist.length - 1) {
                json = string.concat(json, ", ");
            }
        }
        json = string.concat(json, "}}");
        return json;
    }
}
