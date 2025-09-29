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
        assertEq(l3Token.balanceOf(user1), 150);
    }

    function testUserCantMintTwice() public {
        vm.startBroadcast(user1);
        l3Token.userMint(user1);
        vm.expectRevert();
        l3Token.userMint(user1);
        vm.stopBroadcast();
    }

    function testUserApproveStaker() public {
        vm.startPrank(deployer);
        l3Token.setStakerRole(dummyStakerAddress);
        vm.startPrank(user1);
        l3Token.userMint(user1);
        l3Token.userApproveStaker();
        vm.stopPrank();
        assert(l3Token.allowance(user1, dummyStakerAddress) == type(uint256).max);
    }

    function testOnlyTokenHolderCanApprove() public {
        vm.prank(deployer);
        l3Token.setStakerRole(dummyStakerAddress);
        vm.startPrank(user1);
        l3Token.userMint(user1);
        vm.stopPrank();
        vm.prank(user2);
        vm.expectRevert();
        l3Token.userApproveStaker();
    }

    /**
     * Testing if only address with minterrole can mint
     */
    function testOnlyApprovedMinterCanMint() public {
        vm.prank(user1);
        vm.expectRevert();
        l3Token.mintReward(deployer, 20);
    }

    function testGrantMinterRole() public {
        vm.prank(deployer);
        bool res = l3Token.grantMinterRole(user1);
        assert(l3Token.checkMinterRole(user1) == true);
    }

    function testApprovedMinterCanMint() public {
        vm.startPrank(deployer);
        bool res = l3Token.grantMinterRole(user1);
        vm.stopPrank();
        vm.prank(user1);
        l3Token.mintReward(deployer, 20);
        assertEq(l3Token.balanceOf(deployer), 1020);
    }

    function testOnlyOwnerCanGrantMinterRole() public {
        vm.prank(user1);
        vm.expectRevert();
        l3Token.grantMinterRole(user2);
    }

    function testRevokedMinterCantMint() public {
        vm.startPrank(deployer);
        bool res1 = l3Token.grantMinterRole(user1);
        vm.stopPrank();
        vm.startPrank(deployer);
        l3Token.revokeMinterRole(user1);
        vm.stopPrank();
        vm.prank(user1);
        vm.expectRevert();
        l3Token.mintReward(deployer, 20);
    }

    function testContractCanBePaused() public {
        vm.startPrank(deployer);
        l3Token.pauseContract();
        assertEq(l3Token.paused(), true);
    }

    function testOnlyOwnerCanPauseContract() public {
        vm.startPrank(user1);
        vm.expectRevert();
        l3Token.pauseContract();
    }

    function testOnlyOwnerCanUnpauseContract() public {
        vm.prank(deployer);
        l3Token.pauseContract();
        vm.prank(user1);
        vm.expectRevert();
        l3Token.unPauseContract();
    }
}
