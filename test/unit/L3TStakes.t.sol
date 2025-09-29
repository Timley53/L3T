// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {L3Token} from "../../src/L3Token.sol";
import {L3Staker} from "../../src/L3Staker.sol";

contract L3TokenTest is Test {
    L3Token public l3Token;
    L3Staker public l3Staker;
    address deployer = makeAddr("kkk");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address dummyStakerAddress = makeAddr("dummyStakerAddresss");

    function setUp() public {
        vm.startBroadcast(deployer);
        l3Token = new L3Token();
        l3Staker = new L3Staker(address(l3Token));
        l3Token.pauseContract();
        l3Token.setStakerRole(address(l3Staker));
        l3Token.unPauseContract();
        vm.stopBroadcast();
    }

    function testUserStake() public {
        // user joins and mints
        vm.startPrank(user1);
        l3Token.userMint(user1);
        l3Token.userApproveStaker();
        // user call stake
        l3Staker.stake(100);
        assert(l3Staker.getStakeInfo(user1).stakeValue == 100);
        vm.stopPrank();
    }

    function testGetUserPendingReward() public {
        vm.startPrank(user1);
        l3Token.userMint(user1);
        // user approves staker to spend
        l3Token.userApproveStaker();
        // user call stake
        l3Staker.stake(100);
        vm.warp(block.timestamp + 250 days);
        (uint256 reward,) = l3Staker.getUserPendingReward(user1);
        assert(reward > 0);
        vm.stopPrank();
    }

    function testRevertsIfActiveStake() public {
        vm.startPrank(user1);
        l3Token.userMint(user1);
        // user approves staker to spend
        l3Token.userApproveStaker();
        // user call stake
        l3Staker.stake(100);
        vm.expectRevert();
        l3Staker.stake(20);
        vm.stopPrank();
    }

    function testStakerContractCanSpend() public {
        vm.prank(deployer);
        //deployer sets stakerAddress
        l3Token.setStakerRole(address(l3Staker));

        // user joins and mints tokens
        vm.startBroadcast(user1);
        l3Token.userMint(user1);
        uint256 initialBalance = l3Token.balanceOf(user1);
        //user approves staker
        l3Token.userApproveStaker();
        vm.stopBroadcast();

        //user call stake
        vm.prank(user1);
        l3Staker.stake(100);

        uint256 finalBalance = l3Token.balanceOf(user1);
        //
        assert(finalBalance < initialBalance);
    }

    function testDefaultAdminCanCreateRole() public {
        bytes32 role = keccak256("FINANCE_ROLE");
        // Arrange
        vm.prank(deployer);
        l3Staker.createRole(role, user1);
        assert(l3Staker.hasRole(role, user1));
    }

    function testOnlyDefaultAdminCanCreateRole() public {
        bytes32 role = keccak256("FINANCE_ROLE");
        // Arrange
        vm.prank(user2);
        vm.expectRevert();
        l3Staker.createRole(role, user1);
    }

    // test that role parameter is not zero
    function testRoleParameterIsCorrect() public {
        bytes32 role = keccak256("FINANCE_ROLE");

        vm.prank(deployer);
        vm.expectRevert();
        l3Staker.createRole(role, address(0));
    }

    function testOnlyadminCanCallSetPendingInterestRate() public {
        vm.prank(deployer);
        l3Staker.beginPendingInterestRateChange(20);
        assert(l3Staker.getPendingInterestRate() == 20);
    }

    function testOnlyadminCanCallBeginPendingInterestRateChange() public {
        vm.prank(user1);
        vm.expectRevert();
        l3Staker.beginPendingInterestRateChange(20);
    }

    function testPendingRatesIsNotZero() public {
        vm.prank(deployer);
        vm.expectRevert();
        l3Staker.beginPendingInterestRateChange(0);
    }

    function testBeginPendingInterestRateChange() public {
        vm.prank(deployer);
        l3Staker.beginPendingInterestRateChange(20);
        assertEq(l3Staker.getPendingInterestRate(), 20);
    }

    function testCancelPendingInterestRateChange() public {
        vm.prank(deployer);
        l3Staker.beginPendingInterestRateChange(20);
        assert(l3Staker.getPendingInterestRate() == 20);
        vm.prank(deployer);
        l3Staker.cancelPendingInterestRateChange();
        assert(l3Staker.getPendingInterestRate() == 0);
    }

    function testChangeInterestRate() public {
        vm.prank(deployer);
        l3Staker.beginPendingInterestRateChange(20);
        vm.warp(block.timestamp + 8 days);
        vm.prank(deployer);
        l3Staker.changeInterestRate();
        assert(l3Staker.getCurrentInterestRate() == 20);
    }
}
