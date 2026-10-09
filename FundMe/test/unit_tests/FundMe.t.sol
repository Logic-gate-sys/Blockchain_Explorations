//SPDX-License-Identifier: MITpragma 
pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol"; // console prints to the screen
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from '../script/DeployFundMe.s.sol';



contract TestFundMe is Test{
     FundMe fundMe;
     address public USER = makeAddr("user"); 

      function setUp() external{
        DeployFundMe dfundMe = new DeployFundMe();
          fundMe = dfundMe.run();
          vm.deal(USER, 10 ether); // give fake user 10 ethereum
      }
      
      function testMIN_USD() public  {
        assertEq (fundMe.MIN_USD(), 5e18);
      }

      //Test if sender is the owner of contract
      function testOwnerIsSender() public {

        // assertEq(fundMe.i_owner(), msg.sender);
        console.log (address(this));
        console.log (msg.sender);
        assertEq (fundMe.getOwner(), msg.sender);
      }
      modifier funded {
        vm.prank(USER);
        fundMe.fund{value: 10 ether}(); //fund accepts msg.value not a parameter
         _;
      }

      //test fund attempt with low fund
      function testFun() public {
        vm.prank(USER);
        vm.expectRevert(); // expect the following line to fail
        fundMe.fund{value:0.01e18}();
      }

      //test amount funded is equal to what is given 
      function testAmountFundedByUser() public funded {
        console.log("amount sent sucessfully");
        uint256 amountFunded = fundMe.getAmountByUser(USER);
        assertEq(amountFunded,10 ether);

      }

      // test withdrawal
      function testWithdrawal() public funded{
        vm.prank(address(fundMe.getOwner()));
        fundMe.withdraw();
        assertEq(address(fundMe).balance, 0);
      }
}



