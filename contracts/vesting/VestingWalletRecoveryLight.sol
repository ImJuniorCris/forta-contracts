// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * This contract is designed for recovery in case the beneficiary was lost.
 *
 * This contract replicates a storage layout that is compatible with VestingWallet, VestingWalletV1 and
 * VestingWalletV2.
 */
contract VestingWalletRecoveryLight {
    /// Storage
    // Initializable
    uint8 private _initialized;
    bool private _initializing;
    // ContextUpgradeable
    uint256[50] private __gap_1;
    // OwnableUpgradeable
    address private _owner;
    uint256[49] private __gap_2;
    // UUPSUpgradeable
    uint256[50] private __gap_3;
    // ERC1967UpgradeUpgradeable
    uint256[50] private __gap_4;
    // VestingWallet / VestingWalletV1 / VestingWalletV2
    mapping (address => uint256) private _released;
    address private _beneficiary;
    uint256 private _start;
    uint256 private _cliff;
    uint256 private _duration;
    // VestingWalletV1 / VestingWalletV2
    uint256[45] private __gap_5;
    // VestingWalletV2
    uint256 private historicalBalanceMin;
    uint256[45] private __gap_6;

    /// Constants and Events
    // ERC1967UpgradeUpgradeable
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    event Upgraded(address indexed implementation);
    event BeneficiaryUpdate(address newBeneficiary);

    /// @dev The `previousImplementation` address MUST correspond to the real previous implementation.
    /// Otherwise, upgrading to this implementation contract and calling this function will leave the new implementation uninitialized.
    function changeBeneficiaryAndRollbackTo(address newBeneficiary, address previousImplementation) external {
        // restrict to owner, in case the upgrade misses the "andCall" part.
        require(msg.sender == _owner);

        // change beneficiary
        _beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary);

        // ERC1967Upgrade._setImplementation
        require(Address.isContract(previousImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = previousImplementation;
        emit Upgraded(previousImplementation);
    }

    function proxiableUUID() external pure returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }


    function upgradeTo(address newImplementation) external {
        require(msg.sender == _owner);
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external {
        require(msg.sender == _owner);
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }
}
