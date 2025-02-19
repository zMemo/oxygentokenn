// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    IToken public OM;  // Token de elegibilidad
    IToken public OC;  // Token de recompensa
    address public owner;

    uint256 public minOMRequired = 100 * 10**18; // 100 OM (asumiendo 18 decimales)
    uint256 public rewardOC = 10 * 10**18; // 10 OC (asumiendo 18 decimales)

    event AirdropClaimed(address indexed user, uint256 amount);
    event AirdropFunded(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "No eres el owner");
        _;
    }

    constructor(address _OM, address _OC) {
        OM = IToken(_OM);
        OC = IToken(_OC);
        owner = msg.sender;
    }

    function fundAirdrop(uint256 amount) external onlyOwner {
        require(OC.transferFrom(msg.sender, address(this), amount), "Fallo al depositar OC");
        emit AirdropFunded(amount);
    }

    function claimAirdrop() external {
        require(OM.balanceOf(msg.sender) >= minOMRequired, "No tienes suficientes OM");
        require(OC.transfer(msg.sender, rewardOC), "Fallo la transferencia");

        emit AirdropClaimed(msg.sender, rewardOC);
    }

    function withdrawOC(uint256 amount) external onlyOwner {
        require(OC.transfer(owner, amount), "Fallo el retiro de OC");
    }

    function updateAirdropParams(uint256 _minOMRequired, uint256 _rewardOC) external onlyOwner {
        minOMRequired = _minOMRequired;
        rewardOC = _rewardOC;
    }
}
