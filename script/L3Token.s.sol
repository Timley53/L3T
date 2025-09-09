// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {L3Token} from "../src/L3Token.sol";
import {L3Staker} from "../src/L3Staker.sol";

contract L3TokenScript is Script {
    L3Token public l3Token;
    L3Staker public l3Staker;

    function run() public {
        vm.startBroadcast();
        l3Token = new L3Token();
        l3Staker = new L3Staker(address(l3Token));
        vm.stopBroadcast();
    }
}
