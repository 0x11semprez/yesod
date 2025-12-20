//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.27;

import {Ownable} from "./Ownable.sol";

 contract ERC20 is Ownable {

    //@notice You can see all errors here;
    //@dev error handling help you to spend less gas;

    error TransactionFailed(); //keccak256 0xf65044edbd7753e2683b3e1f1116675530a1ea8dc243f8c08c1e4946045da917
    error InsufficientFunds(); //keccak256 0xd2ce7f36f76fcb4610533d95a01cb9b0fdd2b058fe7ffae027e7112f5480b8df
    error OverflowError(); //keccak256 0x3050f6b6cb48b3e4ea702c585b4b686989a4b52ad93ab2d1cbd92df13248bd66
    error AlreadyInitialized(); //keccak256 0x8f076f42b0523e885c670e4a6fe058ff88bd4a1ed50db5541025e052a00a98a5
    error Address0(); //keccak256 0xc5bfd600aba324752e9fa24f3789392bea12ddc8a5a813994f04863d8599fc49

    //@dev As you might know, just events;
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);

    //@dev I choose a pre definied supply;
    uint private _totalSupply = 10000000; 

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    constructor() {
        address _contract = address(this);
        if (_balances[_contract] != 0) {revert AlreadyInitialized()}
        _balances[_contract] = _totalSupply;
    }

    //@notice Some views functions.
    //@dev better to use that because of the control.
    function getTokenName() 
        public 
        view 
        returns(string memory) 
    {
        //@dev remember, strings are special so you need to use nmemory amd as we hardwrire with constamt.
        assembly {
            let TOKENNAME := mload(0x40) 
            mstore(TOKENNAME, 0x20)
            mstore(add(TOKENNAME, 0x20), 5) 
            mstore(add(TOKENNAME, 0x40), shl(216,0x5945534f44)) 
            mstore(0x40,add(TOKENNAME, 0x60)) 
            return (TOKENNAME, 0x60) 
        }
    }


    function getTokenSymbol() 
        public 
        view 
        returns(string memory) 
    {
        assembly {
            let TOKENSYMBOL := mload(0x40)
            mstore(TOKENSYMBOL, 0x20)
            mstore(add(TOKENSYMBOL, 0x20), 3)
            mstore(add(TOKENSYMBOL, 0x40), shl(232, 0x595344))
            mstore(0x40, add(TOKENSYMBOL, 0x60))
            return (TOKENSYMBOL, 0x60)
        }
    }

    function getDecimal() 
        public 
        view 
        returns(uint) 
    {
        return 18;
    }

    function getTotalSupply() 
        public 
        view 
        returns(uint) 
    {
        return 1000000;
    }


    function getBalance() 
        public 
        view 
        returns(uint) 
    {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, _balances.slot)
            let key := keccak256(0x00, 0x40)

            let balanceAccount := sload(key)
            mstore(0x00, balanceAccount)
            return(0x00, 32)
        }
    }

    function getBalanceContract() 
        public 
        view 
        returns(uint)
    {
        assembly {
            mstore(0x00, address())
            mstore(0x20, _balances.slot)
            let key := keccak256(address(),_balances.slot)

            let balanceContract := sload(key)
            mstore(0x00, balanceContract)
            return(0x00, 32)
        }
    }


    function _transfer(address from, address to, uint amount) 
        private 
        returns(bool) 
    {
        assembly {
            mstore(0x00, from)
            mstore(0x20, _balances.slot)
            let fromKey := keccak256(0x00, 0x40)
            let balanceFrom := sload(fromKey)

            mstore(0x00, to)
            mstore(0x20, _balances.slot)
            let toKey := keccak256(0x00, 0x40)
            let balanceTo := sload(toKey)

            if lt(balanceFrom, amount) {
                mstore(0x00, 0x5480b8df)
                revert(0x1c, 0x04)
            }

            let balanceFromAfter := sub(balanceFrom, amount)
            let balanceToAfter := add(balanceTo, amount)

            sstore(fromKey, balanceFromAfter)
            sstore(toKey, balanceToAfter)           
        }

        emit Transfer(from, to, amount);
        return true;

    }

    function transfer(address to, uint amount) 
        public
        returns(bool) 
    {
        address from = msg.sender;
        _transfer(from, to, amount);
        emit Transfer(from, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) 
        public 
        returns(bool) 
    {
        assembly {
            let spender := caller()

            mstore(0x00, from)
            mstore(0x20, _allowances.slot)
            let innerSlot := keccak256(0x00,0x40)

            mstore(0x00, spender)
            mstore(0x20, innerSlot)
            let _allowanceKey := keccak256(0x00, 0x40)
            let _allowance := sload(_allowanceKey)

            mstore(0x00, from)
            mstore(0x20, _balances.slot)
            let fromKey := keccak256(0x00, 0x40)
            let balanceFrom := sload(fromKey)

            mstore(0x00, to)
            mstore(0x20, _balances.slot)
            let toKey := keccak256(0x00, 0x40)
            let balanceTo := sload(toKey)

            if lt(_allowance, amount) {
                mstore(0x00, 0x5480b8df)
                revert(0x1c, 0x04)
            }

            if lt(balanceFrom, amount) {
                mstore(0x00, 0x5480b8df)
                revert(0x1c, 0x04)
            }


            let newAllowance := sub(_allowance, amount)
            sstore(_allowanceKey, newAllowance)

            let balanceFromAfter := sub(balanceFrom, amount)
            sstore(fromKey, balanceFromAfter)

            let balanceToAfter := add(balanceTo, amount)
            sstore(toKey, balanceToAfter)

        }
        
        return true;
    }

    function allowance(address owner, address spender) 
        public 
        view 
        returns(uint) 
    {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, _allowances.slot)
            let innerSlot := keccak256(0x00, 0x40)

            mstore(0x00, spender)
            mstore(0x20, innerSlot)
            let allo := sload(keccak256(0x00, 0x40))

            mstore(0x00, allo)
            return(0x00, 32)
        }

    }

    function approve(address spender, uint amount) 
        external 
        returns(bool) 
    {
        address owner = msg.sender;
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        return true;
    }
    
    function _mint(address to, uint amount) 
        private 
        onlyOwner
        returns(bool)
    {
        assembly {
            
        }

        return true;
    }

    function _burn(uint amount) 
        external 
        onlyOwner 
        returns(bool)
    {
        assembly {
           
        }
        
        return true;

    }

    receive() external payable {}
    fallback() external payable {}
}