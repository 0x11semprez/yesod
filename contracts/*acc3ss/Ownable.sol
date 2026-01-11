//SPDX-Licence-Identifier: MIT;
pragma solidity ^0.8.4;

/*┌⟁⟁⟁┐  SPEC HEADER  ┌⟁⟁⟁┐
  ▸ Inspired by Solmate & Solady: concise contracts + clearer NatSpec.
  ▸ This implementation is for learning; external reviews / suggestions welcome.
  └────────────────────────────────────────────────────────────────────────────*/

/**
 * @title Ownable Contract By Me
 * @author 0x11semprez
 * @notice Minimal ownership access-control primitive (learning implementation).
 *
 * @dev
 * ──⟐ DOC PHILOSOPHY ⟐────────────────────────────────────────────────────────
 * - Inspired by Solmate & Solady to learn how to document contracts cleanly.
 * - In general, it’s safer to rely on well-audited libraries (e.g., OpenZeppelin),
 *   but writing your own is a useful exercise for understanding failure modes.
 * - Any external critique, review, or improvement suggestion is welcome.
 *
 * ──⟐ HIGH-LEVEL BEHAVIOR ⟐────────────────────────────────────────────────────
 * - Stores a current owner address (`_owner`).
 * - Restricts privileged functions using `onlyOwner` modifier.
 * - Allows transferring ownership to a new address.
 * - Allows “disapproving/renouncing” ownership by setting it to address(0).
 *
 * ──⟐ INVARIANTS (INTENDED) ⟐──────────────────────────────────────────────────
 * - `onlyOwner` functions should only be callable by the stored owner.
 * - `owner()` returns the current stored owner.
 * - `oldOwner()` returns the previous owner snapshot.
 *
 * ──⟐ SECURITY NOTES ⟐────────────────────────────────────────────────────────
 * - `disapproveOwnership()` sets owner to the zero address; after that,
 *   owner-gated functions become effectively unreachable.
 * - Assembly is used for reads and authorization checks; keep selectors consistent
 *   with the declared custom errors.
 */
contract Ownable {
    // ──⟐ ERRORS ⟐──────────────────────────────────────────────────────────────
    /**
     * @notice Custom error used as a revert reason for invalid owner inputs.
     * @dev
     * - Declared as a custom error to improve gas efficiency vs revert strings.
     * - The comment shows the keccak hash; in practice reverts use the 4-byte selector.
     */
    error InvalidOwner(); //keccak256 0x49e27cffb37b1ca4a9bf5318243b2014d13f940af232b8552c208bdea15739da

    /**
     * @notice Custom error used when a non-owner calls an onlyOwner function.
     * @dev Custom error pattern: cheaper + clearer failure mode.
     */
    error NotOwner(); //keccak256 0x30cd74712f59d478562d48e2d35de830db72c60a63dd08ae59199eec990b5bc4

    // ──⟐ EVENTS ⟐──────────────────────────────────────────────────────────────
    /**
     * @notice Emitted when ownership is transferred.
     * @param oldOwner The previous owner address (indexed for easy filtering).
     * @param newOwner The new owner address (indexed for easy filtering).
     * @dev
     * - Off-chain services can index this event to track admin changes.
     */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    // ──⟐ STORAGE ⟐─────────────────────────────────────────────────────────────
    /// @dev Current owner storage slot. Only the stored owner should pass `_checkOwner()`.
    address private _owner;

    /// @dev Previous owner snapshot (updated on transfer). Useful for basic history.
    address private _oldOwner;

    // ──⟐ LIFECYCLE ⟐───────────────────────────────────────────────────────────
    /**
     * @notice Initializes the contract by setting the deployer as owner.
     * @dev
     * - Sets `_owner = msg.sender`.
     * - Contains a guard that reverts if msg.sender is the zero address.
     */
    constructor() {
        if (msg.sender == address(0)) {
            revert InvalidOwner();
        }
        _owner = msg.sender;
    }

    // ──⟐ ACCESS CONTROL ⟐──────────────────────────────────────────────────────
    /**
     * @notice Restricts function access to the current owner.
     * @dev
     * - Calls `_checkOwner()` before executing the function body.
     * - Reverts using the NotOwner selector if caller is not owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    // ──⟐ READ API ⟐────────────────────────────────────────────────────────────
    /**
     * @notice Returns the current owner address.
     * @return The current owner.
     *
     * @dev
     * - Uses assembly to load `_owner` directly from storage.
     * - Writes the address to memory, then returns 20 bytes.
     * - `shl(96, owner)` left-pads address into a 32-byte word.
     */
    function owner() public view returns (address) {
        assembly {
            let mainOwner := sload(_owner.slot)
            mstore(0x00, shl(96, mainOwner))
            return(0x00, 20)
        }
    }

    /**
     * @notice Returns the previous owner snapshot.
     * @return The old owner stored in `_oldOwner`.
     *
     * @dev
     * - Assembly mirrors `owner()` but reads `_oldOwner.slot`.
     * - Intended as informational state (not used for authorization).
     */
    function oldOwner() public view returns (address) {
        assembly {
            let OldOwner := sload(_oldOwner.slot)
            mstore(0x00, shl(96, OldOwner))
            return(0x00, 20)
        }
    }

    // ──⟐ INTERNALS ⟐───────────────────────────────────────────────────────────
    /**
     * @notice Checks whether the caller is the stored owner.
     * @dev
     * - Reverts using the NotOwner selector when caller != owner.
     * - Uses assembly for a minimal check: `caller() == sload(_owner.slot)`.
     * - Stores the 4-byte selector at memory[0..32), then reverts with 4 bytes.
     */
    function _checkOwner() internal view {
        assembly {
            if iszero(eq(caller(), sload(_owner.slot))) {
                mstore(0x00, 0x990b5bc4)
                revert(0x1c, 0x04)
            }
        }
    }

    // ──⟐ OWNER ACTIONS ⟐───────────────────────────────────────────────────────
    /**
     * @notice Transfers ownership to `newOwner`.
     * @param newOwner The address that will become the new owner.
     *
     * @dev
     * - onlyOwner gated: caller must pass `_checkOwner()`.
     * - Validates the `newOwner` input in assembly and reverts with InvalidOwner selector.
     * - Updates `_oldOwner` then `_owner`.
     * - Emits {TransferOwnership}.
     *
     * @custom:security
     * - Any bug in owner validation can lock or compromise admin control.
     * - Keep event emission consistent with the stored values you want to expose.
     */
    function transferOwnership(address newOwner) public payable onlyOwner {
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0xa15739da)
                revert(0x1c, 0x04)
            }

            let Owner := sload(_owner.slot)
            let OldOwner := sload(_oldOwner.slot)

            sstore(_oldOwner.slot, Owner)
            sstore(_owner.slot, newOwner)
        }

        emit TransferOwnership(_oldOwner, _owner);
    }

    /**
     * @notice Disapproves (renounces) ownership by setting owner to address(0).
     * @dev
     * - onlyOwner gated.
     * - Writes zero to `_owner.slot` in assembly.
     *
     * @custom:security
     * - After this, no address can satisfy `_checkOwner()` (unless owner is reset elsewhere).
     * - Consider emitting an event if off-chain tracking is needed.
     */
    function disapproveOwnership() public payable onlyOwner {
        assembly {
            sstore(_owner.slot, 0x0000000000000000000000000000000000000000)
        }
    }
}
