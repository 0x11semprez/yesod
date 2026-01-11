//SPDX-Licence-Identifier: MIT;
pragma solidity ^0.8.4;

/*┌⟁⟁⟁┐  GLYPH·MINIMAL  ┌⟁⟁⟁┐
  ▸ Inspired by Solmate & Solady: minimal surface, explicit intent, readable docs.
  ▸ Learning build — external review / critique welcome.
  └────────────────────────────────────────────────────────────────────────────*/

/**
 * @title  ERC20
 * @author Kassim Traore
 * @notice ERC20-like token using storage-slot math + manual ABI encoding in assembly.
 *
 * @dev
 * ──⟐ MAP ⟐───────────────────────────────────────────────────────────────────
 * balances:   _balances[account] = uint
 * allowances: _allowances[owner][spender] = uint
 * supply:     _totalSupply (mutable)
 *
 * ──⟐ ASSUMPTIONS ⟐───────────────────────────────────────────────────────────
 * - Assembly paths must keep selectors consistent with declared custom errors.
 * - Events are used for off-chain observability (indexers / explorers / UI).
 * - Any external feedback is welcome (docs style inspired by Solmate/Solady).
 */
contract ERC20 is Ownable {
    // ──⟐ ERRORS ⟐──────────────────────────────────────────────────────────────
    /// @notice Generic failure signal for token operations.
    /// @dev Custom errors reduce gas vs revert strings.
    error TransactionFailed(); //keccak256 0xf65044edbd7753e2683b3e1f1116675530a1ea8dc243f8c08c1e4946045da917

    /// @notice Thrown when balance is insufficient for the operation.
    error InsufficientFunds(); //keccak256 0xd2ce7f36f76fcb4610533d95a01cb9b0fdd2b058fe7ffae027e7112f5480b8df

    /// @notice Thrown on invalid arithmetic path (overflow/underflow semantics).
    error OverflowError(); //keccak256 0x3050f6b6cb48b3e4ea702c585b4b686989a4b52ad93ab2d1cbd92df13248bd66

    /// @notice Thrown when an init-like routine is called twice.
    error AlreadyInitialized(); //keccak256 0x8f076f42b0523e885c670e4a6fe058ff88bd4a1ed50db5541025e052a00a98a5

    /// @notice Thrown when a non-zero address is required.
    error Address0(); //keccak256 0xc5bfd600aba324752e9fa24f3789392bea12ddc8a5a813994f04863d8599fc49

    // ──⟐ EVENTS ⟐──────────────────────────────────────────────────────────────
    /// @notice Emitted on approvals (owner => spender).
    event Approval(address indexed owner, address indexed spender, uint amount);

    /// @notice Emitted on token movement.
    event Transfer(address indexed from, address indexed to, uint amount);

    /// @notice Extra mint visibility (custom event for this implementation).
    event Mint(address indexed from, address indexed to, uint amount);

    // ──⟐ STATE ⟐───────────────────────────────────────────────────────────────
    /// @dev Pre-defined initial supply (deflation oriented in constructor).
    uint private _totalSupply = 10000000;

    /// @dev account => balance (storage mapping)
    mapping(address => uint) internal _balances;

    /// @dev owner => (spender => allowance) (nested storage mapping)
    mapping(address => mapping(address => uint)) internal _allowances;

    // ──⟐ GENESIS ⟐─────────────────────────────────────────────────────────────
    /**
     * @notice Initializes contract balance and applies a supply decrement.
     * @dev
     * - Credits address(this) with `_totalSupply`.
     * - Calls `decrementTotalSupply(100000)`.
     */
    constructor() {
        address _contract = address(this);
        _balances[_contract] = _totalSupply;
        decrementTotalSupply(100000);
    }

    // ──⟐ METADATA (READ) ⟐─────────────────────────────────────────────────────
    /**
     * @notice Returns the token name (manual ABI encoding).
     * @dev
     * ──⟐ ABI STRING LAYOUT ⟐
     * [0x00..] offset | length | data (padded)
     * - Free memory pointer is at 0x40.
     * @return Token name (string).
     */
    function getTokenName() public view returns (string memory) {
        //@dev remember, strings are special so you need to use nmemory amd as we hardwrire with constamt.
        assembly {
            let TOKENNAME := mload(0x40)
            mstore(TOKENNAME, 0x20)
            mstore(add(TOKENNAME, 0x20), 5)
            mstore(add(TOKENNAME, 0x40), shl(216, 0x5945534f44))
            mstore(0x40, add(TOKENNAME, 0x60))
            return(TOKENNAME, 0x60)
        }
    }

    /**
     * @notice Returns the token symbol (manual ABI encoding).
     * @dev Same pattern as `getTokenName()`.
     * @return Token symbol (string).
     */
    function getTokenSymbol() public view returns (string memory) {
        assembly {
            let TOKENSYMBOL := mload(0x40)
            mstore(TOKENSYMBOL, 0x20)
            mstore(add(TOKENSYMBOL, 0x20), 3)
            mstore(add(TOKENSYMBOL, 0x40), shl(232, 0x595344))
            mstore(0x40, add(TOKENSYMBOL, 0x60))
            return(TOKENSYMBOL, 0x60)
        }
    }

    /**
     * @notice Returns decimals (display precision).
     * @return decimals (uint).
     */
    function getDecimal() public view returns (uint) {
        assembly {
            mstore(0x00, 18)
            return(0x00, 32)
        }
    }

    /**
     * @notice Returns total supply (constant return in this implementation).
     * @dev This does not read `_totalSupply`; it returns a literal.
     * @return totalSupply (uint).
     */
    function getTotalSupply() public view returns (uint) {
        assembly {
            mstore(0x00, 1000000)
            return(0x00, 32)
        }
    }

    // ──⟐ BALANCES (READ) ⟐─────────────────────────────────────────────────────
    /**
     * @notice Returns caller balance using mapping slot derivation.
     * @dev
     * ──⟐ SLOT MATH ⟐
     * key = keccak256(abi.encode(caller(), _balances.slot))
     * balance = sload(key)
     * @return caller balance (uint).
     */
    function getBalance() public view returns (uint) {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, _balances.slot)
            let key := keccak256(0x00, 0x40)

            let balanceAccount := sload(key)
            mstore(0x00, balanceAccount)
            return(0x00, 32)
        }
    }

    /**
     * @notice Returns contract balance using mapping slot derivation.
     * @dev key = keccak256(abi.encode(address(), _balances.slot))
     * @return contract balance (uint).
     */
    function getBalanceContract() public view returns (uint) {
        assembly {
            mstore(0x00, address())
            mstore(0x20, _balances.slot)
            let key := keccak256(0x00, 0x40)

            let balanceContract := sload(key)
            mstore(0x00, balanceContract)
            return(0x00, 32)
        }
    }

    // ──⟐ TRANSFER CORE ⟐───────────────────────────────────────────────────────
    /**
     * @notice Internal transfer primitive.
     * @dev
     * ──⟐ FLOW ⟐
     * - load(from), load(to)
     * - require(fromBalance >= amount) (selector revert)
     * - store(updated balances)
     * - emit Transfer(from,to,amount)
     *
     * @param from Sender.
     * @param to Receiver.
     * @param amount Amount.
     * @return ok Always true on success.
     */
    function _transfer(
        address from,
        address to,
        uint amount
    ) internal returns (bool) {
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
                // selector written directly (4 bytes)
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

    /**
     * @notice Transfers tokens from msg.sender to `to`.
     * @dev Calls `_transfer` then emits Transfer again (double-observability).
     * @param to Receiver.
     * @param amount Amount.
     * @return ok True on success.
     */
    function transfer(address to, uint amount) public returns (bool) {
        address from = msg.sender;
        _transfer(from, to, amount);
        emit Transfer(from, to, amount);

        return true;
    }

    // ──⟐ ALLOWANCE TRANSFER ⟐──────────────────────────────────────────────────
    /**
     * @notice Transfers tokens on behalf of `from` using allowance of msg.sender.
     * @dev
     * ──⟐ NESTED MAPPING SLOT MATH ⟐
     * inner = keccak256(abi.encode(from, _allowances.slot))
     * key   = keccak256(abi.encode(spender, inner))
     * allo  = sload(key)
     *
     * @param from Source.
     * @param to Destination.
     * @param amount Amount.
     * @return ok True on success.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        assembly {
            let spender := caller()

            mstore(0x00, from)
            mstore(0x20, _allowances.slot)
            let innerSlot := keccak256(0x00, 0x40)

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

            let newAllowance := sub(_allowance, amount)
            sstore(_allowanceKey, newAllowance)

            if lt(balanceFrom, amount) {
                mstore(0x00, 0x5480b8df)
                revert(0x1c, 0x04)
            }

            let balanceFromAfter := sub(balanceFrom, amount)
            sstore(fromKey, balanceFromAfter)

            let balanceToAfter := add(balanceTo, amount)
            sstore(toKey, balanceToAfter)
        }

        return true;
    }

    // ──⟐ APPROVALS ⟐───────────────────────────────────────────────────────────
    /**
     * @notice Returns allowance owner=>spender.
     * @dev Reads nested mapping storage via keccak slot derivation.
     * @param owner Token owner.
     * @param spender Approved spender.
     * @return remaining allowance.
     */
    function allowance(
        address owner,
        address spender
    ) public view returns (uint) {
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

    /**
     * @notice Approves `spender` to spend `amount` from msg.sender.
     * @dev Writes to `_allowances` and emits Approval.
     * @param spender Spender.
     * @param amount Amount.
     * @return ok True on success.
     */
    function approve(address spender, uint amount) public returns (bool) {
        address owner = msg.sender;
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

        return true;
    }

    // ──⟐ SUPPLY (INTERNAL) ⟐───────────────────────────────────────────────────
    /**
     * @notice Decreases `_totalSupply` by `amount`.
     * @dev Direct sload/sstore on `_totalSupply.slot`.
     * @param amount Amount to decrement.
     */
    function decrementTotalSupply(uint amount) internal {
        assembly {
            let TotalSupply := sload(_totalSupply.slot)
            let newTotalSupply := sub(TotalSupply, amount)
            sstore(_totalSupply.slot, newTotalSupply)
        }
    }

    // ──⟐ MINT / BURN (INTERNAL) ⟐──────────────────────────────────────────────
    /**
     * @notice Internal mint routine (custom signature).
     * @dev Heavy assembly path; updates balances + `_totalSupply`.
     * @param account Account operand used inside assembly.
     * @param roles Custom flag (project-specific semantics).
     * @return ok True on success.
     */
    function _mint(address account, bool roles) internal returns (bool) {
        assembly {
            let from := account
            mstore(0x00, from)
            mstore(0x20, _balances.slot)
            let fromKey := keccak256(0x00, 0x40)
            let balanceFrom := sload(fromKey)

            if lt(balanceFrom, amount) {
                mstore(0x00, 0x3248bd66)
                revert(0x1c, 0x04)
            }

            let balanceFromAfter := add(balanceFrom, amount)
            sstore(fromKey, balanceFromAfter)

            mstore(0x00, 0x40)
            mstore(0x20, _balances.slot)
            let zeroKey := keccak256(0x00, 0x40)
            let balance0 := sload(zeroKey)

            let balance0After := sub(balance0, amount)
            sstore(zeroKey, balance0After)

            let TotalSupply := sload(_totalSupply.slot)
            if lt(TotalSupply, amount) {
                mstore(0x00, 0x3248bd66)
                revert(0x1c, 0x04)
            }

            let TotalSupplyAfter := add(TotalSupply, amount)
            sstore(_totalSupply.slot, TotalSupplyAfter)
        }

        return true;
    }

    /**
     * @notice Internal burn routine.
     * @dev Assembly path: reduces account balance, adjusts zero bucket, decreases supply.
     * @param account Account to burn from.
     * @param amount Amount to burn.
     * @return ok True on success.
     */
    function _burn(address account, uint amount) internal returns (bool) {
        assembly {
            let from := account
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
                mstore(0x00, 0x3248bd66)
                revert(0x1c, 0x04)
            }

            let TotalSupplyAfter := sub(TotalSupply, amount)
            sstore(_totalSupply.slot, TotalSupplyAfter)
        }
        return true;
    }
}