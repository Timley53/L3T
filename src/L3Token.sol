// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";

// 
/**
 * @title Token name: Learn3Token
 * Token symbol: L3T
 * @author 0x_t31ae Adedokun Timileyin
 * @notice Initial minting for users: Owner sends from their own token balance to the users when users mint, The only other minting that occurs is when users gets rewarded, staker contract calls mint function and mints reward into user's account when they unstake.
 * Initial minting value for every new user is 150
 */

contract L3Token is ERC20 , Ownable, AccessControl, Pausable {

    error L3T_USER_ROLE_NOTFOUND();

    address private L3TStaker;
    /**
     * @notice this mapping is to keep track of anyone who joins the token project already, balance of token held is not added in context here.
     * this mappings can be used to avoid a user minting to a single address twice
     */
    mapping(address holderAddress => bool) public tokenHolders;

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant PAUSABLE_ROLE = keccak256("PAUSABLE_ROLE");


    constructor() ERC20("Learn3Token", "L3T") Ownable(msg.sender){
        _mint(msg.sender, 1000);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSABLE_ROLE, msg.sender);
    }  
    modifier notAddressZero(address addressZero){
        require(addressZero != address(0), "invalid address submitted");
        _;
    }
    modifier onlyStaker{
        require(msg.sender == L3TStaker, "Unauthorized action");
        _;
    }
    modifier onlyTokenHolder(address user){
        require(balanceOf(user) > 0, "Unauthorized action: Not a holder");
        _;
    }


    // ==== owner activity

    // ==== owner transfers token from them to new user, initial minting to users account
    function ownerGiftToken (address user) internal {
         _transfer(owner(), user, 150); // an account => balance has been created for user with token gifted to user
    }

    function setStakerRole(address stakerContractAddress) public onlyOwner whenPaused notAddressZero(stakerContractAddress)  {
         L3TStaker = stakerContractAddress;
        
    }

    /**
     * 
     * @param user the account whose role we are checking
     * @notice only addresses with minterRole access can mint 
     */

    function checkMinterRole(address user) public view returns(bool){
        return hasRole(MINTER_ROLE, user);
    }

    function ownerMint(uint256 value) public onlyOwner{
        _mint(owner(), value);
    }

    function getStaker() public view onlyOwner returns(address staker){
        return L3TStaker;
    } 

      function pauseContract() public  onlyOwner returns (bool) {
         _pause();
    }

    function unPauseContract() public onlyOwner {
        _unpause();
    }


    /**
     * 
     * @dev This function is used to grant Token minter role 
     * @param minter it takes in the staker address and grants it the minter role
     * @return revoked returns bool if revokeRole is executed
     */

    function grantMinterRole(address minter) public onlyRole(getRoleAdmin(MINTER_ROLE)) onlyOwner whenPaused returns(bool){
        grantRole(MINTER_ROLE, minter);
        return true;
    }

    function revokeMinterRole (address minter) public onlyRole(getRoleAdmin(MINTER_ROLE))  onlyOwner whenPaused returns(bool revoked){
        if (!hasRole(MINTER_ROLE, minter)){
            revert L3T_USER_ROLE_NOTFOUND();
        }
       revoked = _revokeRole(MINTER_ROLE, minter);
        return revoked;
    }






    // ==========users
   /**
    * @dev  User joins project and mint token to themselves: owner transfers token from their account to new user's
    * @param userAdd user's address
    */
    //=============== user activity
    
    function userMint(address userAdd) public notAddressZero(userAdd) whenNotPaused  {
        require(!tokenHolders[userAdd], "Hey boi, can't mint twice.");
        ownerGiftToken(userAdd);
        tokenHolders[userAdd] = true;
    }

    /**
     * @dev this creates allowance for staking contract to spend: Staking contract is allowed to spend when user call stake
     * @param allocatedstakeValue amount the user allocates for staking
     */

    function userApproveStaker(uint256 allocatedstakeValue) public notAddressZero(msg.sender) onlyTokenHolder(msg.sender) whenNotPaused {
        
        approve(L3TStaker, allocatedstakeValue);
    }




    // ========== staking contract activity

    /**
     * @dev function is called by staker contract
     * Explanation: this function lets the staking contract spends the allowance the user allocates to it from staking. This means the staking contract also has an account in the balance mapping. Individual staking value can be seen in the staking contract's stakes mapping(it holds the total staked value and when the staking started).
     * only staking contract can call this function 
     * function only callable when token activity is not paused
     */
    function stakerSpendsAllowance(address user) external onlyStaker whenNotPaused  returns(bool success){ 
            // check user's balance if >= stakeValue 
            require(balanceOf(user) >= allowance(user, msg.sender), "Unauthorized:Insufficent balance to stake");
            require(allowance(user, msg.sender) > 0, "No allocated stake value");
           success = transferFrom(user, msg.sender, allowance(user, msg.sender));
    }

    /**
     * @dev this funtion is called when user unstakes and reward has been calculated, this function mints the reward into user's account. This function mints from address(0) since we are calling mint directly. This means total supply is increased when we mint reward. 
     * @param user the user's account we intend to mint rewards to.
     * @param reward the calculated reward after a stipulated time.
     * only account with minting access can call this runction btw.
     */
    function mintReward(address user, uint256 reward) public onlyRole(MINTER_ROLE) whenNotPaused{
        _mint(user, reward);
    }

}

