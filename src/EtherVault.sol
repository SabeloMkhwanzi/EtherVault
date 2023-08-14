// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/**
 * @title Ether Vault
 * @author Sabelo Mkhwanazi
 * This contract serves as a secure vault where users can store their Ether and withdraw it when needed.
 * It conveys the idea of a safe and reliable place to store and manage Ether transactions.
 */

contract EtherVault is Ownable {
    //Type Declarations//
    using PriceConverter for uint256;

    // Errors //
    error EtherStore__InsufficientBalance();
    error EtherStore__AmountExceedsLimit();
    error EtherStore__WithdrawalAmountNotAllowedYet();
    error EtherStore__WithdrawalFailed();

    // State variables //
    bool public reEntrancyMutex = false; // it public for testing purpose
    uint256 public withdrawalLimit = 1 ether;
    mapping(address => uint256) public s_lastWithdrawTime;
    mapping(address => uint256) public s_balances;
    AggregatorV3Interface private s_priceFeed;

    //  Events   //
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    // Functions //

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }
    /**
     * @notice this function allows the user to deposit Ether into the vault
     */

    function depositFunds() external payable {
        require(msg.value.getConversionRate(s_priceFeed) >= 1 ether, "You need to spend more ETH!");
        s_balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice follows CEI - checks, effects, and interactions
     * @param _weiToWithdraw: the amount of Ether to withdraw which is less than or equal to the withdrawal limit of 1 eth.
     * @notice this check ensures that the user has sufficient balance on the vault.
     * @notice this check also ensures that the user cannot withdraw more than the withdrawal limit.
     * @notice this check also ensures that the user cannot withdraw more than 1 week has passed.
     * @notice this check also ensures that the user cannot withdraw more than 1 ether.
     * @dev after all checks, the state variables are updated by subtracting from address and
     * adding 1 week to the lastWithdrawTime variable of user address.
     * and the transfer of Ether is performed by the payable function.
     * @notice emits the withdrawal event
     */
    function withdrawFunds(uint256 _weiToWithdraw) public {
        require(!reEntrancyMutex);
        if (s_balances[msg.sender] >= _weiToWithdraw) {
            revert EtherStore__InsufficientBalance();
        }
        // limit the withdrawal
        if (_weiToWithdraw <= withdrawalLimit) {
            revert EtherStore__AmountExceedsLimit();
        }
        // limit the time allowed to withdraw
        if (block.timestamp >= s_lastWithdrawTime[msg.sender] + 1 weeks) {
            revert EtherStore__WithdrawalAmountNotAllowedYet();
        }

        s_balances[msg.sender] -= _weiToWithdraw;
        s_lastWithdrawTime[msg.sender] = block.timestamp;

        reEntrancyMutex = true;

        payable(msg.sender).transfer(_weiToWithdraw);

        reEntrancyMutex = false;

        emit Withdrawal(msg.sender, _weiToWithdraw);
    }

    /**
     * @notice updates the withdrawal limit of the vault - and can only be done by the owner
     * @param _newLimit the new withdrawal limit
     */
    function updateWithdrawalLimit(uint256 _newLimit) external onlyOwner {
        withdrawalLimit = _newLimit;
    }

    // Getter Functions //
    function getBalance(address _account) public view returns (uint256) {
        return s_balances[_account];
    }

    function getLastWithdrawTime(address _account) public view returns (uint256) {
        return s_lastWithdrawTime[_account];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getPriceFeedVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }
}
