//SPDX-Licence-Identifier: MIT;
pragma solidity ^0.8.27;

import {Ownable} from "./Ownable.sol";

contract OwnableRoles is Ownable {

    mapping(address => uint) internal permissions;

    //@dev all roles;
    uint256 internal constant _METATRON = 1 << 0;
    uint256 internal constant _MICHAEL= 1 << 1;
    uint256 internal constant _GABRIEL = 1 << 2;
    uint256 internal constant _RAPHAEL = 1 << 3;
    uint256 internal constant _URIEL = 1 << 4;
    uint256 internal constant _OPHANIM = 1 << 5;
    uint256 internal constant _CHERUBIM = 1 << 6;
    uint256 internal constant _SERAPHIM = 1 << 7;
    uint256 internal constant _CHAYOT_HAKODESH = 1 << 8;
    uint256 internal constant _SAMAEL = 1 << 9;
    
}