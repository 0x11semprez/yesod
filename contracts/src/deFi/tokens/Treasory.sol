//SPDX-Licence-Identifiere: MIT;
pragma solidity ^0.8.27;

import {Ownable} from "./OwnLib/Ownable.sol";
import {OwnableRoles} from "./OwnLib/OwnableRoles.sol";
import {ERC20} from "./ERC20.sol";

contract Treasory is ERC20, Ownable, OwnableRoles {

    function _mint(address account, bool roles) 
        internal
        returns(bool)
    {
        assembly {

        }

        return true;
    }
    

    function _burn(uint amount) 
        internal
        onlyOwner 
        returns(bool)
    {
        assembly {
            let from := caller()

            mstore(0x00, from)
            mstore(0x20, _balances.slot)
            let fromKey := keccak256(0x00, 0x40)
            let balanceFrom := sload(fromKey)

            if lt(balanceFrom, amount) {
                mstore(0x00, 0x3248bd66)
                revert(0x1c, 0x04)
            }

            let balanceFromAfter := sub(balanceFrom, amount)
            sstore(fromKey, balanceFromAfter)

            mstore(0x00, 0)
            mstore(0x20, _balances.slot)
            let zeroKey := keccak256(0x00, 0x40)
            let balance0 := sload(zeroKey)

            let balance0After := add(balance0, amount)
            sstore(zeroKey, balance0After)

            let TotalSupply := sload(_totalSupply.slot)
            if lt(TotalSupply, amount) {
                mstore(0x00,0x3248bd66)
                revert(0x1c, 0x04)
            }

            let TotalSupplyAfter := sub(TotalSupply, amount)
            sstore(_totalSupply.slot, TotalSupplyAfter)
        }
        return true;
    }
}