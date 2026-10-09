//SPDX-License-Indentifier:MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TestRebaseToken is Test {
    RebaseToken rebase_t;
    Vault vault;
    uint256 constant STARTING_USER_VALUE = 100 ether;
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    //setup function

    function setUp() public {
        // deploy contracts
        vm.deal(USER1, STARTING_USER_VALUE);
        vm.deal(USER2, STARTING_USER_VALUE);
        vm.startPrank(USER1);
        rebase_t = new RebaseToken("RebaseToken", "RBT");
        vault = new Vault(IRebaseToken(address(rebase_t)));
        rebase_t.grandMintAndBurnRole(address(vault));
        // send 2 ether to the vault
        (bool success,) = payable(vault).call{value: 2 ether}("");
        vm.stopPrank();
    }

    // validate interest accrues after deposite
    function testInterestAccruesAfterDeposite(uint256 amount) public {
        // bound
        amount = bound(amount, 1 ether, 6 ether);
        vm.startPrank(USER2);
        // try depositing some funds
        vault.deposite{value: amount}();
        // get user starting balance
        uint256 starting_bal = rebase_t.balanceOf(USER2);
        // forward time by 1 day
        uint256 timeElapse = 5 days;
        vm.warp(block.timestamp + timeElapse);
        uint256 balanceAfterWarp1 = rebase_t.balanceOf(USER2);
        uint256 interest1 = balanceAfterWarp1 - starting_bal;
        // repeat balancing again
        vm.warp(block.timestamp + timeElapse);
        uint256 balanceAfterWarp2 = rebase_t.balanceOf(USER2);
        uint256 interest2 = balanceAfterWarp2 - balanceAfterWarp1;
        vm.stopPrank();
        // assert that interest 1 and interest two are the approximately the same: because interest is linear
        assertApproxEqAbs(interest1, interest2, 5, "Invalid interests");
    }

    function addRewardsToVault(uint256 rewardAmount) public {
        (bool success,) = payable(address(vault)).call{value: rewardAmount}("");
        // vm.assume(success); // Optionally, assume the transfer succeeds
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        address USER3 = makeAddr("user3");
        // deposit  by a user
        vm.startPrank(USER2);
        amount = bound(amount, 1 ether, 20 ether);
        vault.deposite{value: amount}();
        vm.stopPrank();
        // alter the interest rate by rebase owner
        vm.prank(USER1);
        rebase_t.setInterestRate(3e10);
        // transfer to another user
        amountToSend = bound(amountToSend, 1 ether, 5 ether);
        rebase_t.transferFrom(USER2, USER3, amountToSend);
        //
    }

    function testRedeemStraightAway(uint256 amount) public {
        // first less give some huge amount like a reward to the protocol
        address(rebase_t).call{value: 1000 ether}("");
        //user deposits
        vm.startPrank(USER2);
        uint256 balanceBefore = address(USER2).balance;
        // calling a function that accept msg.value
        vault.deposite{value: 2 ether}();
        // redeems amount with not waiting
        vault.redeem(2 ether);
        // assert token remain of user is 0
        assertApproxEqAbs(rebase_t.balanceOf(USER2), 0, 1);
        //assert balance amount of user before and after are approx. the same
        assertApproxEqAbs(USER2.balance, balanceBefore, 1);
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        // let user reduce interestRate
        vm.prank(USER1);
        rebase_t.setInterestRate(3e10);
        // bound deposite amount
        depositAmount = bound(depositAmount, 1 ether, 50 ether);
        bound(time, 10, 20000);
        // deposite some amount
        vm.startPrank(USER2);
        vault.deposite{value: depositAmount}();
        // warp time
        vm.warp(block.timestamp + time);
        // now withdraw
        vault.redeem(depositAmount);
        // assert that user's balance become greather than whan they already had
        assertGt(address(USER2).balance, 100 ether);
    }

    // testGetPrincipleAmount(uint256 amount)
    function testCannotSetInterestRate(uint256 newInterestRate) public {
        address user = makeAddr("user");
        vm.deal(user, 20 ether);
        vm.startPrank(user);
        vm.expectRevert();
        // vm.expectRevert(Ownable.OwnableUnauthorizedAccount.selector);
        // deposite with user
        rebase_t.setInterestRate(3e10);
    }

    // only allowed address can mint/burn
    function testCannotCallMintAndBurn() public {
        vm.startPrank(USER2);
        vm.expectRevert();
        rebase_t.mint(USER2, 19);
    }
}
