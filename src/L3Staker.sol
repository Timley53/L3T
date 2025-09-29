// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin-contracts/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin-contracts/contracts/access/AccessControl.sol";
import {L3Token} from "./L3Token.sol";
import {Pausable} from "@openzeppelin-contracts/contracts/utils/Pausable.sol";
import {SafeERC20} from "@openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * Staker address must have an admin
 * Admin special functions,
 * increase interest rates
 * interest rates should be in pending mode before changing it.
 * two step ownership transfer: setPendingOwnership, PendingOwnerShipdelay, acceptPendingOwnership
 * Pending interest rates and pending ownership transfer should be cancelable
 *
 */
contract L3Staker is Ownable, Pausable,AccessControl {
    // reward = (stakedAmount * elapsedTime * currentInterestRate) / (secondsInYear * 100)

    using SafeERC20 for L3Token;

    //============EVENTS=================
    event ROLECREATED(bytes32 role, address account);
    event PendingInterestRateSet(uint256 newRates);
    event NewInterestRateSet(uint256 newRates);
    event StakeCreated(address staker, uint256 stakeValue, uint256 stakeTime);
    event UnStake(address staker, uint256 stakeValue, uint256 rewardEarned, uint256 stakeTime);

    // =========ERRORS
    error L3S_ACTIVE_STAKE_ONGOING();
    error L3S_STAKING_FAILED();
    error L3S_UNSTAKING_FAILED();
    error InterestRateScheduleStale();
    error INSUFFICIENT_BALANCE();
    error INVALID_VaLUE_ENTERED();
    error STAKER_NOT_APPROVED();
    error INVALID_ADDRESS_ENTERED();
    error INVALID_INTEREST_RATE();

    // changing this will require scheduling
    uint112 public currentInterestRate = 10;
    uint112 private _pendingInterestRate;
    uint256 private _pendingInterestRateSchedule;
    uint256 public interestRateChangeDelay = 2 days; // amount of days to wait before effect.
    uint256 public gracePeriod = 14 days;
    

    uint256 public constant secondsInYear = 365 days;

    string public name = "L3Staker";
    L3Token public L3TokenAddress;

    struct stakeStruct {
        uint256 stakeValue;
        uint256 stakeTimeStart;
    }

    mapping(address stakerAddress => stakeStruct) stakes;

    constructor(address tokenContractAddress)
        Ownable(msg.sender)
         {
        L3TokenAddress = L3Token(tokenContractAddress); // convert this to address only and check corresponding usage.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     *
     * @dev  first e typecast the token contract using its address
     * then we check if the user that intends to stake has anybalance
     *
     */

    // ====Admin role functions

    function createRole(bytes32 role, address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(role != 0x00, "Invalid role entry");
        if (account == address(0)) {
            revert INVALID_ADDRESS_ENTERED();
        }

        grantRole(role, account);

        emit ROLECREATED(role, account);
    }

    // ====Interest Rates change===========

    // ==scheduling
    function _scheduleHasPassed(uint256 schedule) internal returns (bool) {
        return block.timestamp > schedule;
    }

    function beginPendingInterestRateChange(uint112 newRates) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPendingInterestRate(newRates);
    }

    function cancelPendingInterestRateChange() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _roleBackOnInterestChange();
    }

    function changeInterestRate() public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (
            _scheduleHasPassed(_pendingInterestRateSchedule)
                && block.timestamp < (_pendingInterestRateSchedule + 14 days)
        ) {
            _setInterestRate();
        } else {
            revert InterestRateScheduleStale();
        }
    }

    function _setPendingInterestRate(uint112 newRates) internal onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newRates <= 0) {
            revert INVALID_INTEREST_RATE();
        }
        if (newRates == currentInterestRate) {
            revert INVALID_INTEREST_RATE();
        }
        _pendingInterestRate = newRates;
        _pendingInterestRateSchedule = block.timestamp + interestRateChangeDelay;
        emit PendingInterestRateSet(newRates);
    }

    function _setInterestRate() internal onlyRole(DEFAULT_ADMIN_ROLE) {
        currentInterestRate = _pendingInterestRate;
        emit NewInterestRateSet(_pendingInterestRate);
    }

    function _roleBackOnInterestChange() internal onlyRole(DEFAULT_ADMIN_ROLE) {
        _pendingInterestRate = 0;
        _pendingInterestRateSchedule = 0;
    }

    // ====User functions
    /**
     *
     * @param stakeValueInput amount user wants to stake
     * @notice user must have token balance and must have approved the staking contract to spend on their behalf
     * @notice user can only have one active stake at a time
     * @dev remember to find a system to help users increase stake and increase stake yeild.
     */
    function stake(uint256 stakeValueInput) public {
        // token contract
        L3Token l3token = L3Token(L3TokenAddress);
        uint256 userBalance = l3token.balanceOf(msg.sender);

        //    check
        if (stakeValueInput <= 0) revert INVALID_VaLUE_ENTERED();
        if (userBalance < stakeValueInput) revert INSUFFICIENT_BALANCE();

        if (l3token.allowance(msg.sender, address(this)) == 0) revert STAKER_NOT_APPROVED();

        if (getStakeInfo(msg.sender).stakeValue > 0) {
            revert L3S_ACTIVE_STAKE_ONGOING();
        }
        stakes[msg.sender] = stakeStruct({stakeValue: stakeValueInput, stakeTimeStart: block.timestamp});

        // staking contract calls Token contract, and removes from allowance
        bool success = _stakerSpendsAllowance(msg.sender, stakeValueInput);

        emit StakeCreated(msg.sender, stakeValueInput, block.timestamp);

        if (!success) {
            revert L3S_STAKING_FAILED();
        }
    }

    /**
     * @dev function is called by staker contract
     * Explanation: this function lets the staking contract spends the allowance the user allocates to it from staking. This means the staking contract also has an account in the balance mapping. Individual staking value can be seen in the staking contract's stakes mapping(it holds the total staked value and when the staking started).
     * only staking contract can call this function
     * function only callable when token activity is not paused
     */
    function _stakerSpendsAllowance(address user, uint256 stakeValue) internal returns (bool success) {
        L3Token l3token = L3Token(L3TokenAddress);
        // check user's balance if >= stakeValue

        if (l3token.balanceOf(user) < stakeValue) {
            revert INSUFFICIENT_BALANCE();
        }

        success = l3token.transferFrom(user, address(this), stakeValue); // msg.sender here is the staking contract
        return success;
    }

    function unStake() public {
        // token contract
        L3Token token = L3Token(L3TokenAddress);
        require(token.tokenHolders((msg.sender)) == true, "not a token holder");
        require(stakes[msg.sender].stakeValue > 0, "nothing to unstake boi");

        stakeStruct memory userInfo = getStakeInfo(msg.sender);
        (uint256 reward,) = getUserPendingReward(msg.sender);
        token.mintReward(msg.sender, reward);

        // msg.sender for this call points to staker contract address

        (bool success) = token.trySafeTransfer(msg.sender, userInfo.stakeValue);
      emit UnStake(msg.sender, userInfo.stakeValue, reward, userInfo.stakeTimeStart);
        if (!success) {
            revert L3S_UNSTAKING_FAILED();
        }
        delete stakes[msg.sender];
    }

    function getStakeInfo(address user) public view returns (stakeStruct memory stakeInfo) {
        return stakes[user];
    }

    function getUserPendingReward(address user) public view returns (uint256 reward, uint256 elapsedTime) {
        stakeStruct memory userInfo = getStakeInfo(user);
        // check if user has 0 records
        require(
            userInfo.stakeValue != 0 && userInfo.stakeTimeStart != 0,
            "You have no staking record here boi, what you want fuu?"
        );

        // calculating time staked for
        elapsedTime = block.timestamp - userInfo.stakeTimeStart;

        reward = (userInfo.stakeValue * elapsedTime * currentInterestRate) / (secondsInYear * 100);

        return (reward, elapsedTime);
    }

    function getPendingInterestRate() public view returns (uint112) {
        return _pendingInterestRate;
    }
    function getCurrentInterestRate() public view returns (uint112) {
        return currentInterestRate;
    }

    function getPendingInterestRateSchedule() public view returns (uint256) {
        return _pendingInterestRateSchedule;
    }
}
