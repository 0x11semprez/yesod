//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.27;

contract ERC20 {
    //@notice You can see all errors here
    //@dev error handling help you to spend less gas, we need keccak256 because we'll use Yul later.

    error notEnoughETHInYourWallet(); //keccak256 : 0x49661fc744d3a721f3d40a93283704159489576e5de9f2454fe8c1e87afc78eb
    error transactionFailed(); //keccak256 : 0xdccf81a9a2a82c9da94f3d3b593fc9afc9d89f9702a4a18c04b0ad53799c7120


    //@notice Define our variables
    //@dev Pay attention, be creative

    string public constant TOKENNAME = "dontknow";
    string public constant TOKENSYMBOL= "DT";
    uint8 public constant DECIMALS = 18;
    uint public totalSupply = 10000000;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    constructor () {
        
    }

    function transfer(address to, uint amount) public {
        assembly {
            if lt(balance(caller()), mload(amount)) {
                mstore(0x00, 0x7afc78eb)
                mstore(0x1c, 0x04)
            }

            let subbaance := sub(balance(caller()), mload(amount))
            let addbalance := add(balance(mload(amount)), mload(amount))  
        }
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        (bool res, ) = msg.sender.call{value: amount}("");
        if (!res) {revert transactionFailed();}
    }
    
}
