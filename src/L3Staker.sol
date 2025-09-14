// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {L3Token} from "./L3Token.sol";

contract L3Staker is Ownable {

    // reward = (stakedAmount * elapsedTime * interestRate) / (secondsInYear * 100)

    error L3S_ACTIVE_STAKE_ONGOING();
    error L3S_STAKING_FAILED();

    uint256 public constant INTERREST_RATE = 10;
    uint256 public constant secondsInYear = 365 days;

    string public name = "L3Staker";
    L3Token public L3TokenAddress;

    struct stakeStruct {
        uint256 stakeValue;
        uint256 stakeTimeStart;
    }
    mapping(address stakerAddress => stakeStruct) stakes;
    
    constructor(address tokenContractAddress) Ownable(msg.sender){
        L3TokenAddress = L3Token(tokenContractAddress);
    }

    /**
     * 
     * @dev  first e typecast the token contract using its address
     * then we check if the user that intends to stake has anybalance
     * 
     */


    function stake() public {
    // first check if user posses any token balance
       L3Token l3token = L3Token(L3TokenAddress); 
       uint256 userBalance = l3token.balanceOf(msg.sender);
       require(userBalance > 0, "You have no token to stake, what you tryna pull here lassie?");

        if(getStakeInfo(msg.sender).stakeValue > 0){
            revert L3S_ACTIVE_STAKE_ONGOING();
        }

         //   staking record created
        stakes[msg.sender] = stakeStruct({
            stakeValue: l3token.allowance(msg.sender, address(this)),
            stakeTimeStart: block.timestamp
        });
    // staking contract calls Token contract, and removes from allowance
   bool success = l3token.stakerSpendsAllowance(msg.sender);

        if(!success){
            revert L3S_STAKING_FAILED();
        }
    }

    function getStakeInfo(address user) public view returns(stakeStruct memory stakeInfo){
        return stakes[user];
    }

    function getUserPendingReward (address user) public view returns( uint256 reward, uint256 elapsedTime){

        stakeStruct memory userInfo = getStakeInfo(user);
        // check if user has 0 records
        require(userInfo.stakeValue != 0 && userInfo.stakeTimeStart != 0, "You have no staking record here boi, what you want fuu?");

         elapsedTime = block.timestamp - userInfo.stakeTimeStart; // calculating time staked for 

        reward =  (userInfo.stakeValue * elapsedTime * INTERREST_RATE) / (secondsInYear * 100);

        return(reward ,elapsedTime);
    }

    function unStake() public {
        // token contract
        L3Token token = L3Token(L3TokenAddress);
        require(token.tokenHolders((msg.sender)) == true, "not a token holder");
        require(stakes[msg.sender].stakeValue > 0, "nothing to unstake boi");

        stakeStruct memory userInfo = getStakeInfo(msg.sender);
        token.transfer(msg.sender, userInfo.stakeValue); // this msg.sender of this transfer function on the token contract is the staking contract

        (uint256 reward,) = getUserPendingReward(msg.sender);
        token.mintReward(msg.sender, reward);

        // set userStake Data to zero
        delete stakes[msg.sender];
    }

}