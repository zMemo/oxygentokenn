// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import './OCToken.sol';

/**
 * @title OMToken
 * @dev Attacks protection and common smart contract attacks.
 */
contract OMToken is Ownable, Pausable {
    string public constant name = "OM Token";
    string public constant symbol = "OM";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;

    // Balances and assignments
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    // Eventos
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Constructor
     * @param initialSupply Initial amount of tokens to create
     */
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /**
     * @dev Returns the token balance of an account
     * @param account Address of the account to query
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Transfers tokens to another account
     * Implements security checks and follows the checks-effects-interactions pattern
     * @param recipient Address of the recipient
     * @param amount Amount of tokens to transfer
     * @return Success of the operation
     */
    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        // Checks
        require(recipient != address(0), "OMToken: transfer to the zero address");
        require(balances[msg.sender] >= amount, "OMToken: insufficient balance");

        // Effects
        unchecked {
            balances[msg.sender] -= amount;
            balances[recipient] += amount;
        }
        
        // Event (not an interaction but follows the pattern)
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }

    /**
     * @dev Quantity that a spender can spend from the owner's account
     * Implements the zero-first approach security mechanism to prevent front-running attacks
     * @param spender Address of the spender
     * @param amount Amount of tokens to approve
     * @return Success of the operation
     */
    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        require(spender != address(0), "OMToken: approve to the zero address");
        
        // Zero-first approach para mitigar ataques de front-running
        if (amount > 0 && allowances[msg.sender][spender] > 0) {
            require(allowances[msg.sender][spender] == 0, "OMToken: reset allowance to 0 first");
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
        require(sender != address(0), "OMToken: transfer from the zero address");
        require(recipient != address(0), "OMToken: transfer to the zero address");
        require(balances[sender] >= amount, "OMToken: insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "OMToken: transfer amount exceeds allowance");

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
     * @param accountOwner Address of the owner of the account
     * @param spender Address of the spender
     * @return Amount approved
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
        require(spender != address(0), "OMToken: approve to the zero address");
        
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
        require(spender != address(0), "OMToken: approve to the zero address");
        require(allowances[msg.sender][spender] >= subtractedValue, "OMToken: decreased allowance below zero");
        
        unchecked {
            allowances[msg.sender][spender] -= subtractedValue;
        }
        
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Burns tokens reducing the balance of the issuer and the total supply
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) public whenNotPaused {
        // Checks
        require(balances[msg.sender] >= amount, "OMToken: burn amount exceeds balance");
        
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
