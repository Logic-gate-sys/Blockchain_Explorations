//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

/* This will contain two scripts  :
1. for funding 
2. for withdrawal
*/

import{Script} from 'forge-std/Script.sol';
import {DevOpsTools} from 'foundry-devops/src/DevOpsTools.sol'; // For getting the most recent deployed contract 
import {FundMe} from '../src/FundMe.sol';

contract TestFundFundMe is Script{
}