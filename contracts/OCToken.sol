//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Ownable
 * @dev Basic implementation of the Ownable pattern for access control
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new address
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title Pausable
 * @dev Implementation to pause/unpause critical functionalities
 */
contract Pausable is Ownable {
    bool public paused = false;

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Pauses the critical functionalities of the contract
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the critical functionalities of the contract
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title OCToken
 * @dev Implementation of the OC token with security measures
 */
contract OCToken is Pausable {
    string public constant name = "OC";
    string public constant symbol = "OC";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Constructor that initializes the total supply
     * @param initialSupply Initial amount of tokens
     */
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @dev Returns the token balance of an account
     * @param account Address of the account
     * @return Token balance
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Transfers tokens to another account
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     * @return Success of the operation
     */
    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        // Checks
        require(recipient != address(0), "OCToken: transfer to the zero address");
        require(balances[msg.sender] >= amount, "OCToken: insufficient balance");

        // Effects
        unchecked {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
        }
        
        // Events
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Establish quantity that a spender can spend from the owner's account
     * Implements the security mechanism zero-first approach to mitigate front-running attacks
     * @param spender Address of the spender
     * @param amount Amount of tokens to approve
     * @return Success of the operation
     */
    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        require(spender != address(0), "OCToken: approve to the zero address");
        
        // Zero-first approach para mitigar ataques de front-running
        if (amount > 0 && allowances[msg.sender][spender] > 0) {
            require(allowances[msg.sender][spender] == 0, "OCToken: reset allowance to 0 first");
        }
        
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from one account to another using the allowance mechanism
     * @param sender Address of the sender
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     * @return Success of the operation
     */
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        // Checks
        require(sender != address(0), "OCToken: transfer from the zero address");
        require(recipient != address(0), "OCToken: transfer to the zero address");
        require(balances[sender] >= amount, "OCToken: insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "OCToken: transfer amount exceeds allowance");

        // Effects
        unchecked {
            balances[sender] -= amount;
            balances[recipient] += amount;
            allowances[sender][msg.sender] -= amount;
        }
        
        // Events
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Returns the amount that a spender can spend from the owner's account
     * @param accountOwner Address of the owner
     * @param spender Address of the spender
     * @return Approved amount
     */
    function allowance(address accountOwner, address spender) public view returns (uint256) {
        return allowances[accountOwner][spender];
    }

    /**
     * @dev Increases the amount that a spender can spend from the owner's account
     * @param spender Address of the spender
     * @param addedValue Additional value to approve
     * @return Success of the operation
     */
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        require(spender != address(0), "OCToken: approve to the zero address");
        
        unchecked {
            allowances[msg.sender][spender] += addedValue;
        }
        
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decreases the amount that a spender can spend from the owner's account
     * @param spender Address of the spender
     * @param subtractedValue Value to subtract from the approval
     * @return Success of the operation
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        require(spender != address(0), "OCToken: approve to the zero address");
        require(allowances[msg.sender][spender] >= subtractedValue, "OCToken: decreased allowance below zero");
        
        unchecked {
            allowances[msg.sender][spender] -= subtractedValue;
        }
        
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Burns tokens reducing the sender's balance and the total supply
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public whenNotPaused {
        // Checks
        require(balances[msg.sender] >= amount, "OCToken: burn amount exceeds balance");
        
        // Effects
        unchecked {
            balances[msg.sender] -= amount;
            totalSupply -= amount;
        }
        
        // Events
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}
