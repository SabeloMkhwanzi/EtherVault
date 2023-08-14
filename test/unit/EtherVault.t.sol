// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {EtherVault} from "../../src/EtherVault.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployEtherVault} from "../../script/DeployEtherVault.s.sol";

contract EtherVaultTest is Test {
    //  Events   //
    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    EtherVault public etherVault;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);
    address public constant USER1 = address(2);
    address public constant USER2 = address(3);

    function setUp() external {
        DeployEtherVault deployer = new DeployEtherVault();
        (etherVault, helperConfig) = deployer.run();
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    // Run test price feed if set correctly
    function testPriceFeedSetCorrectly() public view {
        address retrievePriceFeed = address(etherVault.getPriceFeed());
        address expectedPriceFeed = helperConfig.activeNetworkConfig();
        assert(retrievePriceFeed == expectedPriceFeed);
    }

    // Run test if Deposit Fails Without Enough ETH
    function testDepositFundsFailsWithoutEnoughETH() public {
        vm.expectRevert();
        etherVault.depositFunds();
    }

    // Run test to if deposited Fund Updated on Data Structure
    function testDepositedFundUpdateDOnDataStructure() public {
        vm.startPrank(USER);
        etherVault.depositFunds{value: SEND_VALUE}();
        vm.stopPrank();
    }

    // Modifier
    modifier deposit() {
        vm.startPrank(USER);
        etherVault.depositFunds{value: SEND_VALUE}();
        assert(address(etherVault).balance > 0);
        _;
    }

    // Run test for withdrawal of funds
    function testWithdrawalFunds() public deposit {
        vm.expectRevert();
        etherVault.withdrawFunds(uint256(SEND_VALUE));
    }

    // Run test for Event Emitted when making Deposit
    function testDepositEventEmitted() public {
        uint256 initialBalance = address(this).balance;
        uint256 initialVaultBalance = address(etherVault).balance;

        // Perform the deposit
        etherVault.depositFunds{value: SEND_VALUE}();

        uint256 finalBalance = address(this).balance;
        uint256 finalVaultBalance = address(etherVault).balance;

        // Check if the event was emitted
        assert(finalVaultBalance == initialVaultBalance + SEND_VALUE);

        // Verify the change in user's balance
        assert(finalBalance == initialBalance - SEND_VALUE);
    }

    // Run Test for Non-Owner
    function testNonOwnerCannotUpdateWithdrawalLimit() public {
        uint256 originalLimit = etherVault.withdrawalLimit();
        uint256 newLimit = 5 ether;

        vm.expectRevert();
        vm.prank(USER);
        etherVault.updateWithdrawalLimit(newLimit);

        assertEq(etherVault.withdrawalLimit(), originalLimit);
    }

    // Run  test for multiple deposits
    function testMultipleDeposits() public {
        vm.deal(USER1, 1 ether);
        vm.deal(USER2, 1 ether);

        vm.prank(USER1);
        etherVault.depositFunds{value: 1 ether}();

        vm.prank(USER2);
        etherVault.depositFunds{value: 1 ether}();

        assertEq(etherVault.getBalance(USER1), 1 ether);
        assertEq(etherVault.getBalance(USER2), 1 ether);
    }

    //Run test that the depositFunds function properly updates the user's balance:
    function testDepositUpdatesBalance() public {
        uint256 beforeBalance = etherVault.getBalance(USER);

        vm.startPrank(USER);
        etherVault.depositFunds{value: 1 ether}();
        vm.stopPrank();

        uint256 afterBalance = etherVault.getBalance(USER);

        assertEq(afterBalance, beforeBalance + 1 ether);
    }

    function testGetterFunctions() public {
        // Deposit some ether
        vm.deal(USER, 1 ether);
        vm.prank(USER);
        etherVault.depositFunds{value: 1 ether}();

        // Test getBalance
        uint256 balance = etherVault.getBalance(USER);
        assertEq(balance, 1 ether);

        // Test getLastWithdrawTime
        uint256 lastTime = etherVault.getLastWithdrawTime(USER);
        assertEq(lastTime, 0); // Should be 0 since no withdrawals yet

        // Test getPriceFeedVersion
        uint256 version = etherVault.getPriceFeedVersion();
        assertGt(version, 0); // Should be > 0 if feed is set
    }

    // Test depositFunds with insufficient ETH
    function testDepositFailsWithInsufficientETH() public {
        vm.expectRevert();
        etherVault.depositFunds{value: 0}(); // Deposit with zero ETH
    }

    // Test withdrawFunds with insufficient balance
    function testWithdrawFailsWithInsufficientBalance() public {
        vm.expectRevert();
        etherVault.withdrawFunds(SEND_VALUE);
    }

    // Test withdrawFunds with amount exceeding limit
    function testWithdrawFailsWithAmountExceedingLimit() public deposit {
        vm.expectRevert();
        etherVault.withdrawFunds(STARTING_USER_BALANCE + SEND_VALUE + 1);
    }

    // Test withdrawFunds before allowed time
    function testWithdrawFailsBeforeAllowedTime() public deposit {
        vm.expectRevert();
        etherVault.withdrawFunds(SEND_VALUE);
    }

    function testStateVariables() public {
        // Test withdrawalLimit initialized to 1 ether
        assertEq(etherVault.withdrawalLimit(), 1 ether);

        // Test balance mapping empty
        assertEq(etherVault.getBalance(USER), 0);

        // Test last withdraw time mapping empty
        assertEq(etherVault.getLastWithdrawTime(USER), 0);

        // Test reEntrancyMutex initialized to false
        assertFalse(etherVault.reEntrancyMutex());

        // Test price feed set correctly
        assertEq(address(etherVault.getPriceFeed()), address(helperConfig.activeNetworkConfig()));

        vm.prank(USER);
        etherVault.depositFunds{value: 1 ether}();

        // Test balance updated
        assertEq(etherVault.getBalance(USER), 1 ether);

        // Test last withdraw time still 0
        assertEq(etherVault.getLastWithdrawTime(USER), 0);
    }
}
