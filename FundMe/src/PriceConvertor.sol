//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 

library PriceConvertor{
    /*  
    A libray in solidity does not hold state variables
    */
    function getPrice(AggregatorV3Interface priceFeed) public view returns (uint256) {
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // answer is in 00000000;
        return uint256(answer *1e10); // to get 10e18 so that I can match msg.values decimal places
    }
    // now lets return that amount the user send in dollors
    function getConversionRate(uint256 _userAmount, AggregatorV3Interface priceFeed) public view returns (uint256){
        uint256 ethAmount=getPrice(priceFeed);
        uint256 ethAmountInUSD;
        return ethAmountInUSD = (_userAmount * ethAmount) / 1e18; // we  multiply first before divison ,because Ehtereum does not deal with decimals
    }

}

