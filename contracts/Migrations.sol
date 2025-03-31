// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Migrations
 * @dev This contract manages Truffle migrations for contract deployment.
 * Its sole purpose is to record which migrations have been executed.
 */
contract Migrations {
  address public owner;
  uint256 public lastCompletedMigration;
  
  event MigrationCompleted(uint256 migration);

  /**
   * @dev Restricts the function to be called only by the owner
   */
  modifier restricted() {
    require(
      msg.sender == owner,
      "Migrations: caller is not the owner"
    );
    _;
  }
  
  /**
   * @dev Initializes the contract setting the deployer as the owner
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Sets the latest completed migration
   * @param completed Number of the completed migration
   */
  function setCompleted(uint256 completed) public restricted {
    lastCompletedMigration = completed;
    emit MigrationCompleted(completed);
  }
}
