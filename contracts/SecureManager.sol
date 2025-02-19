// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OMToken.sol";
import "./OCToken.sol";

contract SecureManager {
    OMToken public omToken;
    OCToken public ocToken;
    
    address public owner;
    mapping(address => bool) public approvers;
    uint256 public requiredApprovals;
    uint256 public approvalCount;
    mapping(address => bool) public hasApproved;

    event WithdrawalRequested(address indexed initiator, uint256 amountOM, uint256 amountOC);
    event WithdrawalApproved(address indexed approver);
    event WithdrawalExecuted(uint256 amountOM, uint256 amountOC);

    

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyApprover() {
        require(approvers[msg.sender], "Not an approver");
        _;
    }

    constructor(address _omToken, address _ocToken, address[] memory _approvers, uint256 _requiredApprovals) {
        require(_requiredApprovals > 0, "Invalid approval count");
        require(_requiredApprovals <= _approvers.length, "Too many approvals required");

        owner = msg.sender;
        omToken = OMToken(_omToken);
        ocToken = OCToken(_ocToken);
        requiredApprovals = _requiredApprovals;

        for (uint256 i = 0; i < _approvers.length; i++) {
            approvers[_approvers[i]] = true;
        }
    }

    function approveWithdrawal() external onlyApprover {
        require(!hasApproved[msg.sender], "Already approved");

        hasApproved[msg.sender] = true;
        approvalCount++;

        emit WithdrawalApproved(msg.sender);
    }

    function executeWithdrawal(address recipient, uint256 amountOM, uint256 amountOC) external onlyOwner {
        require(approvalCount >= requiredApprovals, "Not enough approvals");

        require(omToken.transfer(recipient, amountOM), "OM Transfer failed");
        require(ocToken.transfer(recipient, amountOC), "OC Transfer failed");
        
        // Reset approvals after execution
        for (uint256 i = 0; i < approvalCount; i++) {
            hasApproved[msg.sender] = false;
        }
        approvalCount = 0;

        emit WithdrawalExecuted(amountOM, amountOC);
    }

    function addApprover(address _approver) external onlyOwner {
        approvers[_approver] = true;
    }

    function removeApprover(address _approver) external onlyOwner {
        approvers[_approver] = false;
    }
    
}
