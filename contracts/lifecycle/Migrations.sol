pragma solidity ^0.4.18;

import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Migrations is Ownable {
    uint public LastCompletedMigration;

    function setCompleted(uint completed) public onlyOwner {
        LastCompletedMigration = completed;
    }

    function upgrade(address newAddress) public onlyOwner {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(LastCompletedMigration);
    }
}