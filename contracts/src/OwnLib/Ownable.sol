//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.27;

//@title Ownable Contract By Me
//@dev This not recommended to create your own lib Ownable or SafeERC20 or whatever it is because you could make mistakes, so better to use something who works without a doubt, Trust OpenZellin

contract Ownable {

    //@notice Define error Handling in contracts
    //@dev Better for gas optimisation and code understaning
    error InvalidOwner(); //keccak256 0x49e27cffb37b1ca4a9bf5318243b2014d13f940af232b8552c208bdea15739da
    error NotOwner(); //keccak256 0x30cd74712f59d478562d48e2d35de830db72c60a63dd08ae59199eec990b5bc4

    //@dev Event declaration
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    address private _owner;

    address private _oldOwner;

    constructor() {
        if (msg.sender== address(0)) {revert InvalidOwner();}
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns(address mainOwner) {
        assembly {
            mainOwner := sload(_owner.slot)
        }
    }

    function oldOwner() public view returns(address previousOwner) {
        assembly {
            previousOwner := sload(_oldOwner.slot)
        }
    }
    

    function _checkOwner() internal view {
        assembly {
            if iszero(eq(caller(), sload(_owner.slot))) {
                mstore(0x00, 0x990b5bc4)
                revert(0x1c, 0x04)
            }
        }

    }

    function transferOwnership(address newOwner) public payable onlyOwner{
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0xa15739da)
                revert(0x1c, 0x04)
            }
        }
        _oldOwner = _owner;
        _owner =  newOwner;
        emit TransferOwnership(_oldOwner, _owner);
    }

    function disapproveOwnership() public payable onlyOwner {
        assembly {
            sstore(_owner.slot, 0x0000000000000000000000000000000000000000)
        }
    }
}