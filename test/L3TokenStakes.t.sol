// SPDX-License-Identifier: MIT
   pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {L3Token} from "../src/L3Token.sol";
import {L3Staker} from "../src/L3Staker.sol";

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
        l3Token.setStakerRole(address(l3Staker));
        // console.log("token address:" , address(l3Token));
        // console.log("staker address:",  address(l3Staker));
        // console.log("deployer:" , deployer);
        // console.log("msg.sender:" , msg.sender);
        vm.stopBroadcast();
    }
      
   function testUserUnstakes() public {
        
        // user joins and mints
        vm.startPrank(user1);
        l3Token.userMint(user1);
        uint256 userInitialBalance = l3Token.balanceOf(user1); //getting user initial balance
        // user approves staker to spend
        l3Token.userApproveStaker(120);
        // user call stake
        l3Staker.stake(120);
        // user unstakes
        vm.warp(block.timestamp + 300 days); // time manipulation before unstake to increase yeild
        l3Staker.unStake();
        assert(l3Token.balanceOf(user1) > userInitialBalance); // new balance should be higher than initial balance
        vm.stopPrank(); 
    }

}