//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.4;

import {ERC20} from "ERC20.sol";

contract ERC4626 {
    //--Error Handling--
    error NotSharesAvailable(); //keccak256 0xa83804cdbb49bcaa7256b9f5a8e6f0bec1c8bebea0c8c4a9d705da2549b043c6

    error TransfertToAddress0();

    error TransferFailed(); //keccak 0xbf7e4b28b83e91981237506863a0b375ee2265268eac0c62acc77834d3da44e4

    //--Events--
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    //Custoim Slot
    bytes32 private constant BALANCES_SLOT = 0x16881af15c021539c15cf478f89a62f77ba5e52ebd5499ef557832fd466b6f0d


    //--Variables--
    address private immutable i_asset;
    uint private _totalSupply;


    constructor(address asset) {
        asset = i_asset;
    }

    function asset() 
        public 
        view 
        returns (address assetTokenAddress)
    {
        return _asset;

    }

    function totalSupply() 
        public 
        view 
        returns (uint256) 
    {
      return _totalSupply;  

    }

    function convertToShares(uint256 assets) 
        public 
        view 
        returns (uint256 shares) 
    {
        uint supply = _totalSupply;

        return supply == 0 ? assets: assets.mulDivDown(supply, totalSupply());
    }

    function convertToAssets(uint256 shares)
        public
        view
        returns (uint256 assets)
    {
        uint supply = _totalSuppply;

        return supply == 0 ? shares: shares.mulDivDown(totalAsset(), supply);
    }


    function previewDeposit(uint256 assets) 
        public 
        view 
        returns (uint256 shares) 
    {
        return convertToShares(assets);
    }


    function previewMint(uint256 shares) 
        public 
        view 
        returns (uint256 assets) 
    {
        uint supply = _totalSupply;
        return supply == 0 ? shares : shares.mulDivUp(totalAsset(), supply);
    }

    

    function previewWithdraw(uint256 assets) 
        public 
        view 
        returns (uint256 shares)
    {
        uint supply = _totalSupply;

        return supply == 0 ? assets: assets.mulDivUp(supply, totalAsset());
    }

    function previewRedeem(uint256 shares) 
        public 
        view 
        returns (uint256 assets)
    {
        return convertToAssets(shares);
    }

    function maxWithdraw(address owner) 
        public 
        view 
        returns (uint256 maxAssets) 
    {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, BALANCES_SLOT)

            let OwnerKey := keccak256(0x00, 0x40)
            let BalanceOwner := sload(OwnerKey)

            mstore(0x00, BalanceOwner)
            returm(0x00, 32)
        }

        return convertToAssets(BalanceOwner);
    }

    function maxRedeem(address owner) 
        public 
        view 
        returns (uint256 maxShares)
    {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, BALANCES_SLOT)

            let OwnerKey := keccak256(0x00, 0x40)
            let BalanceOwner := sload(OwnerKey)

            mstore(0x00, BalanceOwner)
            return(0x00, 32)
        }
    }

    function maxDeposit(address receiver) 
        public 
        view 
        returns (uint256 maxAssets) 
    {
        return type(uint256).max;
    }

    function maxMint(address receiver) 
        public 
        view 
        returns (uint256 maxShares) 
    {
        return type(uint256).max;
    }
     
    function deposit(uint256 assets, address receiver) 
        public 
        returns (uint256 shares) 
    {
        uint shares = previewDeposit(assets);

        assembly {
            if lt(shares,0) {
                mstore(0x00, 0x49b043c6)
                revert(0x1c, 0x04)
            }
        }

        i_asset.SafeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(address(this), receiver, assets, shares);

        //a revoir parce que c est pas fou, je dosi recode fix safe math, et safe tyransfert from.
    }

    function mint(uint256 shares, address receiver) 
        public 
        returns (uint256 assets) 
    {

    }


    function withdraw(uint256 assets, address receiver, address owner) 
        public 
        returns (uint256 shares) 
    {

    }

    function redeem(uint256 shares, address receiver, address owner) 
        public 
        returns (uint256 assets) 
    {

    }


    function balanceOf(address owner) 
        public 
        view returns (uint256) 
    {
        assembly {
            mstore(0x00, owner)
            mstore(0x20, BALANCES_SLOT)

            let OwnerKey := keccak256(0x00, 0x40)
            let BalanceOwner := sload(OwnerKey)

            mstore(0x00, BalanceOwner)
            return(0x00, 32)
        }
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint amount) 
        private
        returns(bool sucess)
    {
        assembly {

            let transfer := mload(0x40)

            //Go create our calldata
            mstore(transfer, 0x...)
            mstore(add(transfer, 4), from)
            mstore(add(transfer, 36), to)
            mstore(add(transfer, 68), amount)

            //call in yul 7 arguments(g, a, v, inPtr, inSize, outPtr, outSize)

            let gas := gas()
            let a : = token
            let v := 0
            let inPtr := transfer
            let inSize := 100
            let outPtr := 0
            let outSize := 32

            sucess := call(g, a, v, inPtr, inSize, outPtr, outSize)

            if eq(sucess,  0x0000000000000000000000000000000000000000) {
                mstore(0x00, 0xd3da44e4)
                revert(0x1c, 0x04)
            }
        }
    } 
}

//What this contract is supposed to do ?
// so behind this contract there is strategie, you have all assets and shares

// if you do a little bit of math you start understaning that : 1010 USDC in all assets, but only 1000 shares, so 1 shares is 1.01 the price of the shares , so l,eest design sometghing cool