//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;


/* 
 THIS CONTRACT SCRIPT HAS TO PEFORM TWO MAIN FUNCTIONS:
  1. Deploy mocks when we're on a local  anvil  chain
  2. Keep track of contract address across different chains e.g
      i.  Sepolia ETH/USD
      ii. Mainnet ETH/USD
      etc
*/

import {Script} from 'forge-std/Script.sol';
import {MockV3Aggregator} from '../test/mocks/MockV3Aggregator.sol';
contract HelperConfig is Script{
    /*
     1. If we're on local anvil chain deploy mock
     2. Otherwise grab the existing address from the live network
    */
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address priceFeed;
    }

    constructor(){
        if (block.chainid == 11155111){  // chain id for sepolia is 11155111
         activeNetworkConfig = getSepoliaEthConfig();
        }else if(block.chainid==1){
            activeNetworkConfig = getMainnetEthConfig();
        }
         else{
            activeNetworkConfig = getAnvilEthConfig();
        }
    }
    
    function getSepoliaEthConfig()public pure returns(NetworkConfig memory) {
        // priceFeed
        NetworkConfig memory sepoliaConfig =NetworkConfig({
            priceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
     }
 
    function getMainnetEthConfig() public pure returns (NetworkConfig memory){
        NetworkConfig memory mainnetConfig =NetworkConfig(
            {
             priceFeed:0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            }
        );
        return mainnetConfig;
     }

     function getAnvilEthConfig()public  returns(NetworkConfig memory){

        vm.startBroadcast();
        MockV3Aggregator localContract=new MockV3Aggregator(8,2000e8);
        vm.stopBroadcast();
        
        NetworkConfig memory  anvilEthConfig = NetworkConfig({
            priceFeed: address(localContract)
        });
        return anvilEthConfig;
     }
}