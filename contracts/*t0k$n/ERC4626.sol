//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.4;

import {ERC20} from "ERC20.sol";

/*┌⟁⟁⟁┐  GLYPH·MINIMAL  ┌⟁⟁⟁┐
  ▸ ERC4626-like vault (assets ↔ shares) — learning implementation.
  ▸ Focus: math intuition, slot-math, ABI/assembly patterns, iterative improvements.
  ▸ External review / critique welcome.
  └────────────────────────────────────────────────────────────────────────────*/

/**
 * @title  ERC4626
 * @author Kassim Traore
 * @notice ERC4626-style vault: deposit assets, receive shares; redeem shares, receive assets.
 *
 * @dev
 * ──⟐ MENTAL MODEL (CORE) ⟐───────────────────────────────────────────────────
 * - This vault has an underlying ERC20 asset (`_asset`) and issues "shares" (this token).
 * - Shares represent proportional ownership of the vault's total assets.
 * - Price Per Share (PPS) = totalAssets / totalSupply  (when supply > 0)
 *
 * ──⟐ THE KEY MATH ⟐───────────────────────────────────────────────────────────
 * convertToShares(assets):
 *   - if totalSupply == 0: shares = assets
 *   - else: shares = assets * totalSupply / totalAssets
 *
 * convertToAssets(shares):
 *   - if totalSupply == 0: assets = shares
 *   - else: assets = shares * totalAssets / totalSupply
 *
 * ──⟐ OBSERVABILITY ⟐──────────────────────────────────────────────────────────
 * - {Deposit} and {Withdraw} track vault movement (indexers/UI).
 *
 * ──⟐ ASSEMBLY NOTES ⟐────────────────────────────────────────────────────────
 * - Several functions derive mapping keys manually (keccak256(slot encoding)).
 * - Returning values directly from memory is used for gas + learning.
 * - Error selectors are written directly when reverting (4 bytes).
 *
 * ──⟐ WARNING ⟐───────────────────────────────────────────────────────────────
 * - This is a learning / experimental build. Some parts are intentionally "in progress".
 * - External contributions and review are welcome.
 */
contract ERC4626 is ERC20 {
    //--Error Handling--
    /**
     * @notice Thrown when computed shares are not available / invalid for an operation.
     * @dev Used as a low-level revert selector in assembly paths.
     */
    error NotSharesAvailable(); //keccak256 0xa83804cdbb49bcaa7256b9f5a8e6f0bec1c8bebea0c8c4a9d705da2549b043c6

    /// @notice Thrown when trying to transfer to the zero address.
    error TransfertToAddress0();

    /**
     * @notice Thrown when an ERC20 call (transfer / transferFrom) fails.
     * @dev Common for non-standard tokens or failed low-level calls.
     */
    error TransferFailed(); //keccak 0xbf7e4b28b83e91981237506863a0b375ee2265268eac0c62acc77834d3da44e4

    /// @notice Thrown when a denominator is zero in a division path.
    error DenominatoriIs0(); //keccak 0x7167947f9113ea07d71bdfb7c2fd662e01bc7e551c4d973ba823734b05fe42a2

    //--Events--
    /**
     * @notice Emitted on deposits (assets in, shares out).
     * @param sender The address providing assets.
     * @param owner The address receiving shares.
     * @param assets Amount of underlying deposited.
     * @param shares Amount of shares minted.
     */
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    /**
     * @notice Emitted on withdrawals (shares in, assets out).
     * @param sender The caller initiating the withdrawal.
     * @param receiver The address receiving assets.
     * @param owner The address whose shares are burned.
     * @param assets Amount of underlying withdrawn.
     * @param shares Amount of shares burned.
     */
    event Withdraw(address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);

    //Custom Slot
    /**
     * @notice Custom storage slot used to compute balance keys (owner -> shares).
     * @dev
     * - Instead of relying on Solidity mapping slot, a constant slot is used:
     *   key = keccak256(abi.encode(owner, BALANCES_SLOT))
     * - This pattern is sometimes used for custom storage layout experiments.
     */
    bytes32 private constant BALANCES_SLOT = 0x16881af15c021539c15cf478f89a62f77ba5e52ebd5499ef557832fd466b6f0d


    //--Variables--
    /**
     * @notice Underlying asset token address.
     * @dev Marked immutable: intended to be set once at deployment.
     */
    address private immutable _asset;

    /// @dev Vault share supply (internal tracking in this implementation).
    uint private _totalSupply;

    /// @dev Internal total-asset tracking (vault accounting experiment).
    uint private _totalAsset = address(this);


    /**
     * @notice Creates the vault with the given underlying asset.
     * @param asset Address of the ERC20 underlying token.
     * @dev In an ERC4626 model, `asset()` must remain stable over time.
     */
    constructor(address asset) {
        asset = _asset;
    }

    /**
     * @notice Returns the underlying asset token address.
     * @dev Uses assembly to read the storage slot and return 20 bytes (address).
     * @return assetTokenAddress The underlying asset address.
     */
    function asset() 
        public 
        view 
        returns (address assetTokenAddress)
    {
        assembly {
            let AddressToken := sload(_asset.slot)
            mstore(0x00, shl(96, AddressToken))
            return(0x00, 20)
        }

    }
    
    /**
     * @notice Returns total assets held by the vault.
     * @dev Intended to represent the vault's total underlying balance.
     * @return Total underlying assets (uint256).
     */
    function totalAssets() public view returns(uint256) {
        assembly {
            let BalanceContract := address.this()
            mstore(0x00, BalanceContract)
            return (0x00, 32)
        }
    }

    /**
     * @notice Returns the share total supply.
     * @dev Reads supply tracking variable and returns as uint256.
     * @return Total share supply.
     */
    function totalSupply() 
        public 
        view 
        returns (uint256) 
    {
      assembly {
        let TotalSupply := mload(_totalSupply.slot)
        mstore(0x00, TotalSupply)
        return(0x00, 32)
      }  

    }
    
    /**
     * @notice Converts an amount of assets to shares, using current vault ratio.
     * @dev
     * ──⟐ MATH ⟐
     * - if supply == 0: shares = assets
     * - else: shares = assets * supply / totalAssets
     *
     * @param assets Amount of underlying.
     * @return shares Amount of shares for this deposit size.
     */
    function convertToShares(uint256 assets)
        public
        view
        returns (uint256 shares)
    {
        assembly {
            let supply := sload(_totalSupply.slot)
            switch supply 
            case 0 {
                if iszero(supply) {
                    mstore(0x00, asssets)
                    return(0x00, 32)
                }
            }
            
            default {
                let TotalAssets := sload(_totalAsset.slot)
                let result := div(mul(assets, supply),TotalAssets)
                mstore(0x00, result)
                return(0x00, 32)
            }
    }

    /**
     * @notice Converts an amount of shares to assets, using current vault ratio.
     * @dev
     * ──⟐ MATH ⟐
     * - if supply == 0: assets = shares
     * - else: assets = shares * totalAssets / supply
     *
     * @param shares Amount of shares.
     * @return assets Amount of underlying assets redeemable.
     */
    function convertToAssets(uint256 shares)
        public
        view
        returns (uint256 assets)
    {
        assembly {
            let supply := sload(_totalSupply.slot)
            switch supply 
            case 0 {
                if iszero(supply) {
                    mstore(0x00, shares)
                    return(0x00, 32)
                }
            }
            
            default {
                let TotalAssets := sload(_totalAsset.slot)
                let result := div(mul(shares, TotalAssets),supply)
                mstore(0x00, result)
                return(0x00, 32)
            }
    }

    


    /**
     * @notice Preview shares received for depositing `assets`.
     * @dev Uses convertToShares(assets) with current ratio.
     */
    function previewDeposit(uint256 assets) 
        public 
        view 
        returns (uint256 shares) 
    {
        return convertToShares(assets);
    }


    /**
     * @notice Preview assets required to mint `shares`.
     * @dev Uses an "up-rounded" mulDiv pattern (ceil division) to avoid underpayment.
     */
    function previewMint(uint256 shares) 
        public 
        view 
        returns (uint256 assets) 
    {
        uint supply = _totalSupply;
        return supply == 0 ? shares : shares.mulDivUp(totalAsset(), supply);
    }

    

    /**
     * @notice Preview shares required to withdraw `assets`.
     * @dev Uses an "up-rounded" mulDiv pattern to ensure enough shares are burned.
     */
    function previewWithdraw(uint256 assets) 
        public 
        view 
        returns (uint256 shares)
    {
        uint supply = _totalSupply;

        return supply == 0 ? assets: assets.mulDivUp(supply, totalAsset());
    }

    /**
     * @notice Preview assets received when redeeming `shares`.
     * @dev Uses convertToAssets(shares) with current ratio.
     */
    function previewRedeem(uint256 shares) 
        public 
        view 
        returns (uint256 assets)
    {
        return convertToAssets(shares);
    }

    /**
     * @notice Maximum amount of assets withdrawable by `owner`.
     * @dev
     * - Reads share balance via BALANCES_SLOT-derived storage key.
     * - Then converts that share amount to assets.
     *
     * @param owner Owner of shares.
     * @return maxAssets Maximum withdrawable assets.
     */
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

    /**
     * @notice Maximum amount of shares redeemable by `owner`.
     * @dev Reads share balance via BALANCES_SLOT-derived storage key.
     * @param owner Owner of shares.
     * @return maxShares Maximum redeemable shares.
     */
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

    /**
     * @notice Maximum assets depositable for `receiver`.
     * @dev This implementation returns uint256 max (unbounded deposits).
     */
    function maxDeposit(address receiver) 
        public 
        view 
        returns (uint256 maxAssets) 
    {
        return type(uint256).max;
    }

    /**
     * @notice Maximum shares mintable for `receiver`.
     * @dev This implementation returns uint256 max (unbounded mints).
     */
    function maxMint(address receiver) 
        public 
        view 
        returns (uint256 maxShares) 
    {
        return type(uint256).max;
    }
     

     // ask --> assets --> shares
     // If I give you  assets, how much shares I buy.
    /**
     * @notice Deposits `assets` and mints shares to `receiver`.
     * @dev
     * - shares = previewDeposit(assets)
     * - Validates shares availability (assembly selector revert).
     * - Transfers underlying from msg.sender into the vault.
     * - Mints shares to receiver.
     * - Emits {Deposit}.
     *
     * @param assets Amount of underlying to deposit.
     * @param receiver Address receiving shares.
     * @return shares Amount of minted shares.
     */
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

        _asset.SafeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(address(this), receiver, assets, shares);

        //a revoir parce que c est pas fou, je dois recode fix safe math, et safe tyransfert from.
    }

    // ask --> shares --> assets 
    //IF I give you shares hhow much assets you give me
    /**
     * @notice Mints `shares` to `receiver` by pulling the required `assets`.
     * @dev
     * - assets = previewMint(shares)
     * - Transfers underlying from msg.sender into the vault.
     * - Mints shares to receiver.
     * - Emits {Deposit}.
     *
     * @param shares Amount of shares to mint.
     * @param receiver Address receiving shares.
     * @return assets Amount of assets pulled for mint.
     */
    function mint(uint256 shares, address receiver) 
        public 
        returns (uint256 assets) 
    {
        uint assets = previewMint(shares);

        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

    }


    /**
     * @notice Withdraws `assets` to `receiver`, burning shares from `owner`.
     * @dev
     * - shares = previewWithdraw(assets)
     * - If caller != owner: decreases allowance-like approval in shares terms.
     * - Burns shares from owner.
     * - Emits {Withdraw}.
     * - Transfers underlying to receiver.
     *
     * @param assets Amount of assets to withdraw.
     * @param receiver Address receiving assets.
     * @param owner Address whose shares are burned.
     * @return shares Shares burned for this withdrawal.
     */
    function withdraw(uint256 assets, address receiver, address owner) 
        public 
        returns (uint256 shares) 
    {
        uint shares = previewWithdraw(assets);

        if (msg.sender != owner) {
            uint allowedToSpend = allowance[owner][msg.sender]

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowedToSpend - shares;
        }

        _burn(owner, assets)

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransferFrom(msg.sender, receiver, assets);
    }

    /**
     * @notice Redeems `shares` for `assets`, sending assets to `receiver`.
     * @dev
     * - If caller != owner: decreases allowance-like approval in shares terms.
     * - Computes assets = previewRedeem(shares) and requires non-zero.
     * - Burns shares from owner.
     * - Emits {Withdraw}.
     * - Transfers underlying to receiver.
     *
     * @param shares Amount of shares to redeem.
     * @param receiver Address receiving assets.
     * @param owner Address whose shares are burned.
     * @return assets Assets returned for the redeemed shares.
     */
    function redeem(uint256 shares, address receiver, address owner) 
        public 
        returns (uint256 assets) 
    {
        if (msg.sender != owner) {
            uint allowedToSpend = allowance[owner][msg.sender]

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowedToSpend - shares;
        }

        require((assets = previewRedeem(shares)) != 0, "Zero Assets");

        _burn(owner, assets)

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransferFrom(msg.sender, receiver, assets);
    }


    /**
     * @notice Returns share balance of `owner` using custom BALANCES_SLOT.
     * @dev
     * ──⟐ SLOT MATH ⟐
     * key = keccak256(abi.encode(owner, BALANCES_SLOT))
     * balance = sload(key)
     *
     * @param owner Address to query.
     * @return Share balance.
     */
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

    /**
     * @notice Internal safeTransferFrom helper (low-level call).
     * @dev
     * ──⟐ GOAL ⟐
     * - Build calldata manually and call token.transferFrom(from,to,amount).
     * - Check success and revert with TransferFailed selector on failure.
     *
     * ──⟐ CALL SIGNATURE ⟐
     * call(gas, token, 0, inPtr, inSize, outPtr, outSize)
     *
     * @param token ERC20 token to call.
     * @param from Source address.
     * @param to Destination address.
     * @param amount Amount to transfer.
     * @return sucess True if call succeeds (as defined by low-level call semantics).
     */
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

// if you do a little bit of math you start understaning that : 1010 USDC in all assets, but only 1000 shares, so 1 shares is 1.01 the price of the shares , so l,eest design sometghing cool fais pareil avec ce contrat explique bien tout mais ne change pas le code
