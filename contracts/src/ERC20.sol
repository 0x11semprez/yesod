//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.27;

import "./Ownable.sol";

contract ERC20 is Ownable {
    //@notice You can see all errors here;
    //@dev error handling help you to spend less gas;

    error notEnoughETHInYourWallet(); 
    error transactionFailed(); 
    error notEnoughAllowToSpend();
    error  insufficientFunds();
    error overflowError();


    //@dev As you might know, just events;
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);

    //@dev I choose a pre definied supply;
    uint private _totalSupply = 10000000; 

    mapping(address account => uint amount) private _balances;
    mapping(address account => mapping(address account => uint amount)) private _allowances;

    constructor(address owner) {
        owner = msg.sender;
        _balances[owner] += _totalSupply;
    }

    //@notice Some views functions.
    //@dev better to use that because of the control.
    function getTOKENNAME() 
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


    function getTOKENSYMBOL() 
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

    function getDECIMAL() 
        public 
        view 
        returns(uint) 
    {
        return 18;
    }

    function getTOTALSUPPLY() 
        public 
        view 
        returns(uint) 
    {
        return 1000000;
    }


    function getBALANCE(address account) 
        public 
        view 
        returns(uint balanceaccount) 
    {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, _balances.slot)
            balanceaccount := sload(keccak256(0x00, 0x40))
        }
    }


    function _transfer(address from, address to, uint amount) 
        private 
        returns(bool) 
    {
        assembly {
            mstore(0x00, from)
            mstore(0x20, _balances.slot)
            let balanceFrom := sload(keccak256(0x00, 0x40))

            mstore(0x00, to)
            mstore(0x20, _balances.slot)
            let balanceTo := sload(keccak256(0x00, 0x40))

            if lt(balanceFrom, amount) {
                mstore(0x00, 0x7afc78eb)
                revert(0x1c, 0x04)
            }

            let balanceFromAfter := sub(balanceFrom, amount)
            let balanceToAfter := add(balanceTo, amount)

            sstore(balanceFrom, balanceFromAfter)
            sstore(balanceTo, balanceToAfter)           
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

    function transferFrom(address owner, address spender, uint256 amount) 
        public 
        returns(bool) 
    {
        address spender = msg.sender;
        uint newAllowance;
        assembly {
            mstore(0x00, owner)
            mstore(0x20, _allowances.slot)
            let innerSlot := keccak256(0x00,0x40)

            mstore(0x40, innerSlot)
            mstore(0x60, spender)
            let _allowance := sload(keccak256(0x40, 0x80))

            mstore(0x00, owner)
            mstore(0x20, _balances.slot)
            let balanceOwner := sload(keccak256(0x00, 0x40))

            mstore(0x00, spender)
            mstore(0x20, _balances.slot)
            let balanceSpender := sload(keccak256(0x00, 0x40))

            if lt(_allowance, amount) {
                mstore(0x00, 0xfb37dadb)
                revert(0x1c, 0x04)
            }

            let newAllowance := sub(_allowance, amount)
            sstore(_allowance, newAllowance)

            let balanceOwnerAfter := sub(balanceOwner, amount)
            sstore(balanceOwner, balanceOwnerAfter)

            let balanceSpenderAfter := add(balanceSpender, amount)
            sstore(balanceSpender, balanceSpednerAfter)

        }
        
        _transfer(owner, spender, amount);
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
    
    function _mint(uint amount) 
        external 
        onlyOwner
        returns(bool)
    {
        assembly {
            let _TotalSupply := sload(_totalSupply.slot)

            mstore(0x00, _TotalSupply)
            mstore(0x20, _balances.slot)

            let balanceBefore := sload(keccak256(0x00, 0x40))
            let balanceAfter := add(balanceBefore, amount)

            if lt(balanceAfter, balanceBefore) {
                mstore(0x00, 0x792bbe49)
                revert(0x1c, 0x04)
            }
        }

        return true;
    }

    function _burn(uint amount) 
        external 
        onlyOwner 
        returns(bool)
    {
        assembly {
            let _TotalSupply := sload(_totalSupply.slot)

            mstore(0x00, _TotalSupply)
            mstore(0x20, _balances.slot)

            let balanceBefore := sload(keccak256(0x00, 0x40))
            let balanceAfter := sub(balanceBefore, amount)

            if gt(balanceAfter, balanceBefore) {
                mstore(0x00, 0x792bbe49)
                revert(0x1c, 0x04)
            }
        }

        return true;
    }

    receive() external payable {}
    fallback() external payable {}
}