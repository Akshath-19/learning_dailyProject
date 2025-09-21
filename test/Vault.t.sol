// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import forge-std for cheatcodes and console logging
import "forge-std/Test.sol";
// Import our contract
import "../src/Vault.sol";
import "forge-std/console.sol";

contract VaultTest is Test {
    Vault public vault;

    // Define test addresses
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public attacker = makeAddr("attacker");

    // Set a fixed deposit amount
    uint256 public constant DEPOSIT_AMOUNT = 10 ether;

    // This function runs before each test
    function setUp() public {
        // We prank the owner to make them the msg.sender for the constructor
        vm.prank(owner);
        vault = new Vault();
    }

    // Test 1: Can the owner withdraw?
    function test_WithdrawByOwner() public {
        // Arrange: User1 deposits ETH
        vm.deal(user1, DEPOSIT_AMOUNT);
        vm.prank(user1);
        vault.deposit{value: DEPOSIT_AMOUNT}();

        // Act & Assert: Owner tries to withdraw. Should not revert.
        vm.prank(owner);
        vault.withdraw();

        // Assert: Contract balance should be 0 after withdrawal.
        assertEq(vault.getBalance(), 0);
    }

    // Test 2: Can a non-owner NOT withdraw? (This is a negative test)
    function test_RevertWhen_WithdrawByNotOwner() public {
        // Arrange: User1 deposits, Attacker has no funds but that's not the point
        vm.deal(user1, DEPOSIT_AMOUNT);
        vm.prank(user1);
        vault.deposit{value: DEPOSIT_AMOUNT}();

        // Act & Assert: Attacker tries to withdraw. Should revert with our custom error.
        vm.prank(attacker);
        vm.expectRevert(Vault__NotOwner.selector);
        vault.withdraw();
    }

    // Test 3: Can a user deposit successfully?
    function test_Deposit() public {
        // Arrange: Give user1 some ETH
        vm.deal(user1, DEPOSIT_AMOUNT);

        // Act: User1 deposits
        vm.prank(user1);
        vault.deposit{value: DEPOSIT_AMOUNT}();

        // Assert: Check contract balance increased
        assertEq(vault.getBalance(), DEPOSIT_AMOUNT);
        // Check the user's tracked balance increased
        assertEq(vault.getUserBalance(user1), DEPOSIT_AMOUNT);
    }

    // Test 4: Fuzz Test for multiple deposits from different users!
    function testFuzz_Deposits(uint96 amount1, uint96 amount2) public {
        // vm.assume prevents overflow/underflow for this test setup
        vm.assume(amount1 > 0);
        vm.assume(amount2 > 0);

        // Fund users
        vm.deal(user1, amount1);
        vm.deal(user2, amount2);

        // User1 deposits
        vm.prank(user1);
        vault.deposit{value: amount1}();
        assertEq(vault.getBalance(), amount1);

        // User2 deposits
        vm.prank(user2);
        vault.deposit{value: amount2}();

        // Check final balance is the sum
        assertEq(vault.getBalance(), amount1 + amount2);
        // Check individual user balances
        assertEq(vault.getUserBalance(user1), amount1);
        assertEq(vault.getUserBalance(user2), amount2);
    }

    // Test 5: Events are emitted
    function test_DepositEmitsEvent() public {
        vm.deal(user1, DEPOSIT_AMOUNT);

        // We expect a specific event to be emitted
        vm.expectEmit(true, true, false, true);
        // We emit the event we expect
        emit Vault.Deposit(user1, DEPOSIT_AMOUNT);

        vm.prank(user1);
        vault.deposit{value: DEPOSIT_AMOUNT}();
    }
}