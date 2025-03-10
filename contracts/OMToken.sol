// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import './OCToken.sol';


contract OMToken is Ownable, Pausable {
    string public constant name = "OM Token";
    string public constant symbol = "OM";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    event Burn(address indexed burner, uint256 value);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "OMToken: transfer to the zero address");
        require(balances[msg.sender] >= amount, "OMToken: insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "OMToken: transfer to the zero address");
        require(balances[sender] >= amount, "OMToken: insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "OMToken: transfer amount exceeds allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address accountOwner, address spender) public view returns (uint256) {
        return allowances[accountOwner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        require(allowances[msg.sender][spender] >= subtractedValue, "OMToken: decreased allowance below zero");
        allowances[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function burn(uint256 amount) public onlyOwner whenNotPaused {
        require(balances[msg.sender] >= amount, "OMToken: burn amount exceeds balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}
