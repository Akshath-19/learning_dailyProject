// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Custom error for gas efficiency
error Vault__NotOwner();

contract Vault {
    // State variables
    address private immutable i_owner;
    mapping(address => uint256) private s_balances;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    // Modifier
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Vault__NotOwner();
        }
        _;
    }

    // Set the deployer as the owner
    constructor() {
        i_owner = msg.sender;
    }

    // Allow users to deposit ETH
function deposit() public payable {
    uint256 currentBalance = s_balances[msg.sender];
    
    // Check for potential overflow before adding
    if (msg.value > type(uint256).max - currentBalance) {
        revert("Deposit amount would cause overflow");
    }
    
    s_balances[msg.sender] = currentBalance + msg.value;
    emit Deposit(msg.sender, msg.value);
}
    // Allow only the owner to withdraw ALL ETH
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(i_owner).call{value: amount}("");
        require(success, "Withdraw failed");
        emit Withdraw(i_owner, amount);
    }

    // Getter functions
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getUserBalance(address user) public view returns (uint256) {
        return s_balances[user];
    }
}