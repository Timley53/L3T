// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {L3Token} from "../../src/L3Token.sol";

contract L3TokenTest is Test {
    L3Token public l3Token;
    address deployer = makeAddr("deployer");
    address user1 = makeAddr("user1");
    address dummyStakerAddress = makeAddr("dummyStakerAddresss");
    address user2 = makeAddr("user2");

    function setUp() public {
        vm.startBroadcast(deployer);
        l3Token = new L3Token();
        vm.stopBroadcast();
    }

    function testUserMint() public {
        vm.startBroadcast(user1);
        l3Token.userMint(user1);
        vm.stopBroadcast();
       assertEq( l3Token.balanceOf(user1), 150);
    }

    function testUserCantMintTwice() public {
        vm.startBroadcast(user1);
        l3Token.userMint(user1);
        vm.expectRevert();
        l3Token.userMint(user1);
        vm.stopBroadcast();
    }

    function testUserApproveStaker () public {
        vm.prank(deployer);
        l3Token.setStakerRole(dummyStakerAddress);
        vm.startBroadcast(user1);
        l3Token.userMint(user1);
        l3Token.userApproveStaker(30);
        vm.stopBroadcast();
        assert(l3Token.allowance(user1,dummyStakerAddress) == 30);
        
    }

    function testOnlyTokenHolderCanApprove()public{
        vm.prank(deployer);
        l3Token.setStakerRole(dummyStakerAddress);
        vm.startPrank(user1);
        l3Token.userMint(user1);
        vm.stopPrank();
        vm.prank(user2);
        vm.expectRevert();
        l3Token.userApproveStaker(30);
    }

    function testStakerSpends() public {
        vm.prank(deployer);//deplyer sets stakerAddress
        l3Token.setStakerRole(dummyStakerAddress);
        vm.startBroadcast(user1);// user joins and mints tokens
        l3Token.userMint(user1);
        l3Token.userApproveStaker(30); //user approves staker
        vm.stopBroadcast();
        vm.prank(dummyStakerAddress); //staker address impersonates and withraw stake allowance
        l3Token.stakerSpendsAllowance(user1, 30);
        assert(l3Token.allowance(user1,dummyStakerAddress) == 0 && l3Token.balanceOf(dummyStakerAddress) == 30);
    }

}