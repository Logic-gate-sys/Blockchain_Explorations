//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

/* This will contain two scripts  :
1. for funding 
2. for withdrawal
*/

import{Script} from 'forge-std/Script.sol';
import {DevOpsTools} from 'foundry-devops/src/DevOpsTools.sol'; // For getting the most recent deployed contract 
import {FundMe} from '../src/FundMe.sol';

contract FundFundMe is Script{

    uint256 PAID_AMOUNT = 0.10 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
       FundMe(payable(mostRecentlyDeployed)).fund{value:PAID_AMOUNT}();
       vm.stopBroadcast();

    }


    function run() external{
     address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
     fundFundMe(mostRecentlyDeployed);
    }

}

contract WithDrawFundMe{

}