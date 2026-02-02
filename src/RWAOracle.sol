
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/AccessControl.sol";


contract RWAOracle is AccessControl {
bytes32 public constant ORACLE_ADMIN = keccak256("ORACLE_ADMIN");


uint256 public nav; // e.g. 1e18 = 1 USDC


event NavUpdated(uint256 newNav);


constructor(uint256 initialNav) {
_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
_grantRole(ORACLE_ADMIN, msg.sender);
nav = initialNav;
}


function updateNav(uint256 newNav) external onlyRole(ORACLE_ADMIN) {
require(newNav > 0, "invalid NAV");
nav = newNav;
emit NavUpdated(newNav);
}
}