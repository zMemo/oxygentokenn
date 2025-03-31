// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OMToken.sol";
import "./OCToken.sol";

contract SecureManager {
    OMToken public omToken;
    OCToken public ocToken;
    
    address public owner;
    address[] public approversList;
    mapping(address => bool) public approvers;
    uint256 public requiredApprovals;
    uint256 public approvalCount;
    mapping(address => bool) public hasApproved;
    
    bool public withdrawalRequested;
    address public withdrawalRecipient;
    uint256 public withdrawalAmountOM;
    uint256 public withdrawalAmountOC;

    event WithdrawalRequested(address indexed initiator, address indexed recipient, uint256 amountOM, uint256 amountOC);
    event WithdrawalApproved(address indexed approver);
    event WithdrawalCancelled(address indexed initiator);
    event WithdrawalExecuted(address indexed recipient, uint256 amountOM, uint256 amountOC);
    event ApproverAdded(address indexed approver);
    event ApproverRemoved(address indexed approver);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyApprover() {
        require(approvers[msg.sender], "Not an approver");
        _;
    }
    
    modifier withdrawalInProgress() {
        require(withdrawalRequested, "No withdrawal request in progress");
        _;
    }

    constructor(address _omToken, address _ocToken, address[] memory _approvers, uint256 _requiredApprovals) {
        require(_omToken != address(0), "OMToken: address zero");
        require(_ocToken != address(0), "OCToken: address zero");
        require(_requiredApprovals > 0, "Invalid approval count");
        require(_requiredApprovals <= _approvers.length, "Too many approvals required");

        owner = msg.sender;
        omToken = OMToken(_omToken);
        ocToken = OCToken(_ocToken);
        requiredApprovals = _requiredApprovals;

        for (uint256 i = 0; i < _approvers.length; i++) {
            require(_approvers[i] != address(0), "Approver: address zero");
            
            // Avoid duplicate approvers
            require(!approvers[_approvers[i]], "Duplicate approver");
            
            approvers[_approvers[i]] = true;
            approversList.push(_approvers[i]);
        }
    }
    
    // Function to request a withdrawal (only the owner can initiate)
    function requestWithdrawal(address recipient, uint256 amountOM, uint256 amountOC) external onlyOwner {
        require(recipient != address(0), "Recipient: address zero");
        require(amountOM > 0 || amountOC > 0, "At least one amount must be greater than zero");
        require(!withdrawalRequested, "Withdrawal already requested");
        require(omToken.balanceOf(address(this)) >= amountOM, "OM balance insufficient");
        require(ocToken.balanceOf(address(this)) >= amountOC, "OC balance insufficient");
        
        // Effects
        withdrawalRequested = true;
        withdrawalRecipient = recipient;
        withdrawalAmountOM = amountOM;
        withdrawalAmountOC = amountOC;
        
        // Reset approvals for new request
        resetApprovals();
        
        emit WithdrawalRequested(msg.sender, recipient, amountOM, amountOC);
    }

    function approveWithdrawal() external onlyApprover withdrawalInProgress {
        require(!hasApproved[msg.sender], "Already approved");

        // Effects
        hasApproved[msg.sender] = true;
        approvalCount++;

        emit WithdrawalApproved(msg.sender);
    }
    
    function cancelApproval() external onlyApprover withdrawalInProgress {
        require(hasApproved[msg.sender], "You have not approved this withdrawal");
        
        // Effects
        hasApproved[msg.sender] = false;
        approvalCount--;
        
        emit WithdrawalApproved(msg.sender);
    }
    
    function cancelWithdrawal() external onlyOwner withdrawalInProgress {
        // Effects
        withdrawalRequested = false;
        resetApprovals();
        
        emit WithdrawalCancelled(msg.sender);
    }

    function executeWithdrawal() external onlyOwner withdrawalInProgress {
        require(approvalCount >= requiredApprovals, "Not enough approvals");
        require(omToken.balanceOf(address(this)) >= withdrawalAmountOM, "OM balance insufficient");
        require(ocToken.balanceOf(address(this)) >= withdrawalAmountOC, "OC balance insufficient");
        
        // Effects
        address recipient = withdrawalRecipient;
        uint256 amountOM = withdrawalAmountOM;
        uint256 amountOC = withdrawalAmountOC;
        
        // Reset state before external calls
        withdrawalRequested = false;
        resetApprovals();
        
        // Interactions
        if (amountOM > 0) {
            require(omToken.transfer(recipient, amountOM), "OM Transfer failed");
        }
        
        if (amountOC > 0) {
            require(ocToken.transfer(recipient, amountOC), "OC Transfer failed");
        }

        emit WithdrawalExecuted(recipient, amountOM, amountOC);
    }
    
    // Internal function to reset all approvals
    function resetApprovals() internal {
        for (uint256 i = 0; i < approversList.length; i++) {
            address approver = approversList[i];
            if (hasApproved[approver]) {
                hasApproved[approver] = false;
            }
        }
        approvalCount = 0;
    }

    function addApprover(address _approver) external onlyOwner {
        require(_approver != address(0), "Approver: address zero");
        require(!approvers[_approver], "Approver already exists");
        
        approvers[_approver] = true;
        approversList.push(_approver);
        
        emit ApproverAdded(_approver);
    }

    function removeApprover(address _approver) external onlyOwner {
        require(approvers[_approver], "Not an approver");
        
        approvers[_approver] = false;
        
        for (uint256 i = 0; i < approversList.length; i++) {
            if (approversList[i] == _approver) {
                approversList[i] = approversList[approversList.length - 1];
                approversList.pop();
                break;
            }
        }
        
        if (hasApproved[_approver] && withdrawalRequested) {
            hasApproved[_approver] = false;
            approvalCount--;
        }
        
        emit ApproverRemoved(_approver);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be address zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    function getApproversCount() external view returns (uint256) {
        return approversList.length;
    }
}
