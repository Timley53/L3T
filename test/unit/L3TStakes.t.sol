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
         //getting user initial balance
        // uint256 userInitialBalance = l3Token.balanceOf(user1);
        // user approves staker to spend
        l3Token.userApproveStaker(120);
        // user call stake
        l3Staker.stake();       
        assert(l3Staker.getStakeInfo(user1).stakeValue == 120);
        vm.stopPrank();
    }

    function testGetUserPendingReward () public {
        vm.startPrank(user1);
        l3Token.userMint(user1);
        // user approves staker to spend
        l3Token.userApproveStaker(120);
        // user call stake
        l3Staker.stake();  
        vm.warp(block.timestamp + 250 days); 
        (uint256 reward ,) = l3Staker.getUserPendingReward(user1);
        assert(reward > 0);   
        vm.stopPrank();
    }

    function testRRevertsIfActiveStake () public {
        vm.startPrank(user1);
        l3Token.userMint(user1);
         //getting user initial balance
        // uint256 userInitialBalance = l3Token.balanceOf(user1);
        // user approves staker to spend
        l3Token.userApproveStaker(120);
        // user call stake
        l3Staker.stake();       
        vm.expectRevert();
        l3Staker.stake(); 
        vm.stopPrank();      

    }
      
}