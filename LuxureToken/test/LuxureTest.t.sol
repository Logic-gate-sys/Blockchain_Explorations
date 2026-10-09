//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployLuxure} from "../script/DeployLuxure.s.sol";
import {LuxureToken} from "../src/LuxureToken.sol";

contract LuxureTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    uint256 constant INITIAL_AMOUNT = 10 ether;
    address OWNER = makeAddr("owner");
    address SPENDER = makeAddr("spendender");
    LuxureToken ltoken;

    function setUp() public {
        // deal users some money
        vm.deal(OWNER, INITIAL_AMOUNT);
        vm.deal(SPENDER, INITIAL_AMOUNT);
        vm.prank(OWNER);
        ltoken = new LuxureToken(1000);
    }

    // test total supply
    function testTotalTokenSupply() public {
        vm.prank(OWNER);
        assert(ltoken.totalSupply() == 1000);
    }

    // test deployer receives all initial tokens
    function testDeployerGetsAllTokens() public {
        uint256 intitialSupply = ltoken.totalSupply();
        assertEq(intitialSupply, ltoken.balanceOf(OWNER));
    }

    //Test token transfer
    function testTranserEmitsTransferEvent() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, true, false);
        emit Transfer(OWNER, SPENDER, 50);
        ltoken.transfer(SPENDER, 50);
    }

    // ================ MORE TESTS ================================

    function testTransferChangesBalances() public {
        vm.prank(OWNER);
        ltoken.transfer(SPENDER, 100);

        assertEq(ltoken.balanceOf(OWNER), 900);
        assertEq(ltoken.balanceOf(SPENDER), 100);
    }

    function testTransferZeroTokens() public {
        vm.prank(OWNER);
        bool success = ltoken.transfer(SPENDER, 0);
        assertTrue(success);

        assertEq(ltoken.balanceOf(OWNER), 1000);
        assertEq(ltoken.balanceOf(SPENDER), 0);
    }

    function testTransferAllTokens() public {
        vm.prank(OWNER);
        bool success = ltoken.transfer(SPENDER, 1000);
        assertTrue(success);

        assertEq(ltoken.balanceOf(OWNER), 0);
        assertEq(ltoken.balanceOf(SPENDER), 1000);
    }

    function testTransferInsufficientBalanceShouldRevert() public {
        vm.expectRevert(); // catches any revert
        vm.prank(SPENDER); // SPENDER has 0 tokens initially
        ltoken.transfer(OWNER, 1);
    }

    function testTransferToZeroAddressShouldSucceed() public {
        vm.prank(OWNER);
        ltoken.transfer(address(0), 10);
        /// burning token

        assertEq(ltoken.balanceOf(OWNER), 990);
        assertEq(ltoken.balanceOf(address(0)), 10); // Only works if balanceOf doesn't restrict zero address
    }

    function testBalanceOfReturnsCorrectValue() public {
        vm.prank(OWNER);
        ltoken.transfer(address(0), 500); // burn half of the total supply
        assertEq(ltoken.balanceOf(OWNER), 500);
        assertEq(ltoken.balanceOf(SPENDER), 0);
        assertEq(ltoken.balanceOf(address(0)), 500);
    }

    function testDoubleTransferSequence() public {
        vm.prank(OWNER);
        ltoken.transfer(SPENDER, 300);

        vm.prank(SPENDER);
        ltoken.transfer(OWNER, 100);

        assertEq(ltoken.balanceOf(OWNER), 800); // 1000 - 300 + 100
        assertEq(ltoken.balanceOf(SPENDER), 200); // 300 - 100
    }
    // test

    function testTransferEventWithCorrectParams() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, true, false);
        emit Transfer(OWNER, SPENDER, 123);
        ltoken.transfer(SPENDER, 123);
    }

    // test transfer revert when spender allowed value is exhausted
    function testTransferFromRevertsWhenAllowanceExhausted() public {
        vm.prank(OWNER);
        ltoken.approve(SPENDER, 100);

        // Simulate SPENDER using up the entire allowance
        vm.prank(SPENDER);
        ltoken.transferFrom(OWNER, SPENDER, 100);

        // Try to transfer again with 0 remaining allowance
        vm.expectRevert(); // Generic revert expected
        vm.prank(SPENDER);
        ltoken.transferFrom(OWNER, SPENDER, 1);
    }

    // test transfer cannot occur on un-allowed user
    function testTransferFromWithoutApprovalReverts() public {
        vm.expectRevert();
        vm.prank(SPENDER); // SPENDER has 0 allowance
        ltoken.transferFrom(OWNER, SPENDER, 10);
    }

    // test emit Approval

    function testApproveEmitsApprovalEvent() public {
        vm.prank(OWNER);
        vm.expectEmit(true, true, true, false);
        emit Approval(OWNER, SPENDER, 200);
        ltoken.approve(SPENDER, 200);
    }

    function testAllowanceUpdatedCorrectly() public {
        vm.prank(OWNER);
        ltoken.approve(SPENDER, 300);
        assertEq(ltoken.allowance(OWNER, SPENDER), 300);
    }
}
