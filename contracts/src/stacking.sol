//SPDX-Licence-Identifier: MIT
pragma solidity 0.8.27;

import { Ownable } from './OwnLib/Ownable.sol';
import { ERC20 } from './ERC20.sol';

contract Stacing is Ownable, ERC20 {

    error NotEnoughToken();
    error LockTimeNotFinished();
    
    IERC20 public immutable i_token;
    IERC20 public immutable i_tokenrewarded;


    constructor(IERC20 _token) {
        i_token = _token;
    }

    struct User {
        uint amount;
        uint rewards;
        uint lastUpdate;
    }

    mapping(address => User) private _users;
    mapping(address => uint) private _balances;



    function seeUser() public view onlyOwner {}

    function apy() public view returns(uint) {}

    function timeLock() public view returns(uint) {}

    function calculateRate() public view returns(uint) {}

    function stake() external payable {}

    function claim() public {}

    receive() external payable {}

    fallback() external payable {} //@dev will add a proxy I think

}