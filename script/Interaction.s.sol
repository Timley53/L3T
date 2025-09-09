// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {L3Token} from "../src/L3Token.sol";
import {L3Staker} from "../src/L3Staker.sol";


contract SetStakerRole is Script {

        address public l3Token;
        address public staker;
        address deployer = makeAddr("kkk");


    function FxnTester(address deployedContract, address deployedStaker) public {
        // deployer sets the staker address and its role
        // vm.prank(deployer);
        L3Token(deployedContract).setStakerRole(deployedStaker);
        }

   
    // 1. setUp: prepare addresses, load contract
    function setUp() public {
        l3Token = vm.envAddress("Token_address");
        staker = vm.envAddress("Staker_address");
    }

    // 2. run: actually interact
    function run() public {
        vm.startBroadcast(vm.envUint("APK"));
    
        FxnTester(l3Token, staker);

        vm.stopBroadcast();
    }
}


contract OwnerMint is Script{
    address l3Token;
    function setUp() public{
        l3Token = vm.envAddress("Token_address");
    }

    function run() public {
        vm.startBroadcast(vm.envUint("APK"));
        L3Token(l3Token).ownerMint(1000);
        vm.stopBroadcast();
    }
}