//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.27;

contract ERC20 {
    //@notice You can see all errors here;
    //@dev error handling help you to spend less gas, we need keccak256 because we'll use Yul later.;

    error notEnoughETHInYourWallet(); //keccak256 : 0x49661fc744d3a721f3d40a93283704159489576e5de9f2454fe8c1e87afc78eb
    error transactionFailed(); //keccak256 : 0xdccf81a9a2a82c9da94f3d3b593fc9afc9d89f9702a4a18c04b0ad53799c7120
    error notEnoughAllowToSpend();
    error  insufficientFunds();//keccak256 0x952d78c4b28c81a938fc7be8bf876b23e880e7620854eee740c78ce3fb37dadb


    //@notice It is for all dev front and back can receive informartion;
    //@dev As you might know, just events;
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);


    //@notice Define our variables
    //@dev Pay attention, be creative
    uint8 private DECIMALS = 18;
    uint private _totalSupply = 10000000;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    constructor(address owner) {
        owner = msg.sender;
        _balances[owner] += _totalSupply;
    }
    //@notice Some views functions.
    //@dev better to use that because of the control.
    function getTOKENNAME() public view returns(string memory) {
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


    function getTOKENSYMBOL() public view returns(string memory) {
        assembly {
            let TOKENSYMBOL := mload(0x40)
            mstore(TOKENSYMBOL, 0x20)
            mstore(add(TOKENSYMBOL, 0x20), 3)
            mstore(add(TOKENSYMBOL, 0x40), shl(232, 0x595344))
            mstore(0x40, add(TOKENSYMBOL, 0x60))
            return (TOKENSYMBOL, 0x60)
        }
    }

    function getDECIMAL() public view returns(uint) {
        return 18;
    }

    function getTOTALSUPPLY() public view returns(uint) {
        return 1000000;
    }

    function getBALANCE(address owner) public view returns(uint) {
        return _balances[owner];
        // assembly {
        //     mstore(0x00, owner)
        //     mstore(0x20, _balances.slot)
        //     let result := sload(keccak256(0x00, 0x40))
        // }
    }

    function _transfer(address from, address to, uint amount) 
        private 
        returns(bool) 
    {
        assembly {
            mstore(0x00, from)
            mstore(0x20, _balances.slot)
            let balanceFrom := sload(keccak256(0x00, 0x40))
            if lt(balanceFrom, amount) {
                mstore(0x00, 0x7afc78eb)
                revert(0x1c, 0x04)
            }
        }

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;

    }

    function transfer(address to, uint amount) 
        public
        returns(bool) 
    {
        _transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint _allowance = _allowances[from][msg.sender];
        uint newAllowance;
        assembly {
            if lt(_allowance, amount) {
                mstore(0x00, 0xfb37dadb)
                revert(0x1c, 0x04)
            }
            newAllowance := sub(_allowance, amount)
        }

        _allowances[from][msg.sender] = newAllowance;
        
        _transfer(from, to, amount);
        return true;
    }

    function allowance(address owner, address spender) 
        public 
        view 
        returns(uint256) 
    {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, spender)
            mstore(0x40, _allowances.slot)
            let allo := sload(keccak256(0x00, 0x60))
        }

    }

    function approve(address spender, uint amount) 
        external 
        returns(bool) 
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _mint() internal {}
    function _burm() internal {}

}