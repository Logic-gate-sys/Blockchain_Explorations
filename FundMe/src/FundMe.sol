// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.18;

/*
 this contract has two main things to do: 
1. allow eth to be sent to the contract
2. allow funds to be withdrawn
*/

import {PriceConvertor} from './PriceConvertor.sol'; // import PriceConvertor libray for use
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; 

error NotOwner();

// main contract
contract FundMe{
    using PriceConvertor for uint256; // make all uint256 have acess to price convertor Library functions
    address private immutable i_owner; // saving gas by immutable keyword; since owner gets set once in the constructor
    uint256 public constant MIN_USD= 5e18;// Ethereum value is power 18 of Wei; also constant keyword says gas for a variable that is set once;
    AggregatorV3Interface private priceFeed; //Object


    //================== keeping track of our funders and their total amounts  ==============
    address[] public funders;
    mapping(address funders => uint256 amount) private fundersToAmount;

    constructor(address price_feed){
       i_owner = msg.sender; // when the contract is deployed the owner become the deployer account address
       priceFeed = AggregatorV3Interface(price_feed); 
    }
    
    // get AggregatorV3Interface priceFeed version
    function getVersion() public view returns (uint256){
          return priceFeed.version();
    }

    // function to allow funding 
    function fund() public payable{
        require(msg.value.getConversionRate(priceFeed) >= MIN_USD, "Transaction Failed !, please send atleast $5"); // value must be atleast 0.05 Ethereum for transaction to work
        // is someone successfully funded us, we keep their detaial
        funders.push(msg.sender); // add adrees to list
        fundersToAmount[msg.sender] += msg.value; // keep track of all fundings receive and their address
    }
    // withdraw fund
    function withdraw() public onlyOwner{
        for(uint256 index=0;index < funders.length;index++){
            address funder = funders[index]; // get the funder's address
            fundersToAmount[funder] = 0;  // set the entire value associated with the funder to 0;
        }
        funders = new address[](0); // creates a new funder address
        // Different ways of sending native token like thereum;
        //1. transfer
        payable(msg.sender).transfer(address(this).balance); // transfer the balance here to the sender's address
        //2. send
        bool sucess= payable(msg.sender).send(address(this).balance); // this returns a boolean
        require(sucess,"Error!, balance could not be transfered"); // check that the sending was sucessful or return error
        //3. call
        (bool callSucess, /*bytes memory dataReturned */) = payable(msg.sender).call{value: address(this).balance}(""); // call is the recommed process
        require(callSucess,"Call Failed");
    }

    modifier  onlyOwner(){
        //require(msg.sender== i_owner,"Get out here!, thief, you're not the owner");  // making sure that the caller of this function is the owner
        if(msg.sender !=i_owner){  // saving gas
            revert NotOwner();
            }
        _;           // this means continue anything else;
    }
    // ==================== When money is sent to our our contract without invoking the right functions 'fund"
    receive() external payable { 
        fund(); // if the invoker does not have a calldata associated
    }

    fallback() external payable { 
        fund();// if the invoking body has a calldata associated
    }
    
    //------------------- GETTERS ----------------------
    function getAmountByUser(address user) external view returns(uint256){
         return fundersToAmount[user];
    }

    function getOwner() external view returns(address){
        return i_owner;
    }
} 