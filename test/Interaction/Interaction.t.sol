// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {L3Token} from "../../src/L3Token.sol";
import {L3Staker} from "../../src/L3Staker.sol";
import {SetStakerRole} from "../../script/Interaction.s.sol";

contract InteractionTest is Test {
    L3Token public l3Token;
    L3Staker public l3Staker;
    address deployer = makeAddr("kkk");
    address user1 = makeAddr("user1");
    // address dummyStakerAddress = makeAddr("dummyStakerAddresss");

    function setUp() public {
        vm.startBroadcast(deployer);
        l3Token = new L3Token();
        l3Staker = new L3Staker(address(l3Token));
        // l3Token.setStakerRole(address(l3Staker));
        vm.stopBroadcast();
    }

    function testSetStakerRole() public {
        SetStakerRole sSR = new SetStakerRole();
        sSR.FxnTester(address(l3Token), address(l3Staker));
        vm.startPrank(deployer);
        assertEq(l3Token.getStaker(), address(l3Staker));
        vm.stopPrank();
    }
}
