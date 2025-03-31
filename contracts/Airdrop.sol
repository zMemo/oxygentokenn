// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract Airdrop {
    IToken public OM;  // Eligible token
    IToken public OC;  // Reward token
    address public owner;

    uint8 private immutable omDecimals;
    uint8 private immutable ocDecimals;

    uint256 public minOMRequired; 
    uint256 public rewardOC; 
    
    mapping(address => bool) public hasClaimed;

    event AirdropClaimed(address indexed user, uint256 amount);
    event AirdropFunded(uint256 amount);
    event AirdropParamsUpdated(uint256 minOMRequired, uint256 rewardOC);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    constructor(address _OM, address _OC) {
        require(_OM != address(0), "OM: zero address");
        require(_OC != address(0), "OC: zero address");
        
        OM = IToken(_OM);
        OC = IToken(_OC);
        owner = msg.sender;
        
        omDecimals = OM.decimals();
        ocDecimals = OC.decimals();
        
        minOMRequired = 100 * 10**omDecimals;
        rewardOC = 10 * 10**ocDecimals;
    }

    function fundAirdrop(uint256 amount) external onlyOwner {
        require(amount > 0, "Cantidad debe ser mayor que cero");
        
        uint256 previousBalance = OC.balanceOf(address(this));
        
        require(OC.transferFrom(msg.sender, address(this), amount), "Failed to deposit OC");
        
        require(OC.balanceOf(address(this)) == previousBalance + amount, "Error in the transfer");
        
        emit AirdropFunded(amount);
    }

    function claimAirdrop() external {
        require(OM.balanceOf(msg.sender) >= minOMRequired, "You don't have enough OM");
        require(!hasClaimed[msg.sender], "You have already claimed the airdrop");
        require(OC.balanceOf(address(this)) >= rewardOC, "Contract has insufficient funds");
        
        hasClaimed[msg.sender] = true;
        
        require(OC.transfer(msg.sender, rewardOC), "Transfer failed");

        emit AirdropClaimed(msg.sender, rewardOC);
    }

    function withdrawOC(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(OC.balanceOf(address(this)) >= amount, "Insufficient balance");
        
        require(OC.transfer(owner, amount), "Withdrawal failed");
    }

    function updateAirdropParams(uint256 _minOMRequired, uint256 _rewardOC) external onlyOwner {
        require(_minOMRequired > 0);
        require(_rewardOC > 0);
        
        minOMRequired = _minOMRequired;
        rewardOC = _rewardOC;
        
        emit AirdropParamsUpdated(_minOMRequired, _rewardOC);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
