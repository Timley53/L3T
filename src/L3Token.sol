// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";

// Token name Learn#Token
// Token symbol L3T

contract L3Token is ERC20 , Ownable {

    address private L3TStaker;
    mapping(address holderAddress => bool) public tokenHolders;

    constructor() ERC20("Learn3Token", "L3T") Ownable(msg.sender){
        _mint(msg.sender, 1000);
    }  
    modifier notAddressZero(address addressZero){
        require(addressZero != address(0), "invalid address submitted");
        _;
    }
    modifier onlyStaker{
        require(msg.sender == L3TStaker, "Unauthorized action");
        _;
    }
    modifier onlyTokenHolder{
        require(tokenHolders[msg.sender], "Unauthorized action: Not a holder");
        _;
    }


    // ==== owner activity

    // ==== owner transfers token from them to new user, initial minting to users account
    function ownerGiftToken (address user) internal {
         _transfer(owner(), user, 150); // an account => balance has been created for user with token gifted to user
    }

    function setStakerRole(address stakerContractAddress) public onlyOwner notAddressZero(stakerContractAddress) {
         L3TStaker = stakerContractAddress;
    }

    function mintReward(address user, uint256 reward) public onlyStaker {
        _mint(user, reward);
    } // minter should have a designated role with multiple wallets, this is to be done after i'm fully done with everything

    function ownerMint(uint256 value) public onlyOwner{
        _mint(owner(), value);
    }

    function getStaker() public view onlyOwner returns(address staker){
        return L3TStaker;
    } 

    // ==========================================================================================


    //=============== user activity

    // user joins project and mint token to themselves: owner transfers token from themselve to new user
    function userMint(address userAdd) public notAddressZero(userAdd)  {
        require(!tokenHolders[userAdd], "Hey boi, can't mint twice.");
        ownerGiftToken(userAdd);
        tokenHolders[userAdd] = true;
    }

    // user approves staking contract and creates allowance
    function userApproveStaker(uint256 allocatedstakeValue ) public notAddressZero(msg.sender) onlyTokenHolder {
        require(balanceOf(msg.sender) != 0, "No token to stake, You're butters bro");
        approve(L3TStaker, allocatedstakeValue);
    }

    // basically staking contract withdraws approved stake amount
    function stakerSpendsAllowance(address user, uint256 stakeValue) external onlyStaker { 
            // check user's balance if >= stakeValue 
            require(balanceOf(user) >= stakeValue, "Unauthorized:Insufficent balance to stake");
            require(allowance(user, msg.sender) >= stakeValue, "Stake amount higher than stake allowance");
            transferFrom(user, msg.sender, stakeValue);
    }

}



