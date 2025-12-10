//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.27;

contract ERC20 {
    //@notice You can see all errors here;
    //@dev error handling help you to spend less gas, we need keccak256 because we'll use Yul later.;

    error notEnoughETHInYourWallet(); //keccak256 : 0x49661fc744d3a721f3d40a93283704159489576e5de9f2454fe8c1e87afc78eb
    error transactionFailed(); //keccak256 : 0xdccf81a9a2a82c9da94f3d3b593fc9afc9d89f9702a4a18c04b0ad53799c7120
    error notEnoughAllowToSpend();

    //@notice It is for all dev front and back can receive informartion;
    //@dev As you might know, just events;
    event Approval(address indexed owner, address indexed spender, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);


    //@notice Define our variables
    //@dev Pay attention, be creative

    string public constant TOKENNAME = "dontknow";
    string public constant TOKENSYMBOL= "DT";
    uint8 public constant DECIMALS = 18;
    uint public totalSupply = 10000000;

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    function _transfer(address from, address to, uint amount) 
        private
        returns(bool) 
    {
        assembly {
            if lt(balance(caller()), mload(amount)) {
                mstore(0x00, 0x7afc78eb)
                mstore(0x1c, 0x04)
            }

            let subbaance := sub(balance(caller()), mload(amount))
            let addbalance := add(balance(mload(amount)), mload(amount))  
        }
        
        _balances[from] -= amount;
        _balances[to] += amount;
    }

    function transfer(address to, uint amount) 
        public
        returns(bool) 
    {
        _transfer(msg.sender, to, amount);
        return true;
        emit Transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if (_allowances[from][msg.sender] < value) {
            revert("Insufficient allowance");
        }

        _allowances[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }



    function allowance(address owner, address spender) 
        public 
        view 
        returns(uint256) 
    {
        
        return _allowances[owner][spender];

    }

    function approve(address spender, uint value) 
        external 
        returns(bool) 
    {
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;

    }

}