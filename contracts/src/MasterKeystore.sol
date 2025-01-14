// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ControllerProofs, KeystoreLib} from "./libs/KeystoreLib.sol";
import {ValueHashPreimages} from "./libs/ValueHashLib.sol";

contract MasterKeystore {
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                              EVENTS                                            //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Emitted when a Keystore record is updated.
    ///
    /// @param id The Keystore identifier of the updated record.
    /// @param account The account address.
    /// @param newValueHash The new ValueHash stored in the record.
    event KeystoreRecordSet(bytes32 id, address account, bytes32 newValueHash);

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                            STORAGE                                             //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice The Keystore records.
    ///
    /// @dev The ValueHash MUST be keyed by account to fulfill the ERC-4337 validation phase storage rules.
    mapping(bytes32 id => mapping(address account => bytes32 valueHash)) public records;

    ////////////////////////////////////////////////////////////////////////////////////////////////////
    //                                        PUBLIC FUNCTIONS                                        //
    ////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Updates a Keystore record to a new ValueHash.
    ///
    /// @param id The identifier of the Keystore record to update.
    /// @param account The account address.
    /// @param currentValueHashPreimages The preimages of the current ValueHash in the Keystore record.
    /// @param newValueHash The new ValueHash to store in the Keystore record.
    /// @param newValueHashPreimages The preimages of the new ValueHash.
    /// @param l1BlockData OPTIONAL: An L1 block header, RLP-encoded, and a proof of its validity.
    ///                              If present, it is expected to be `abi.encode(l1BlockHeaderRlp, l1BlockHashProof)`.
    ///                              This OPTIONAL L1 block header is meant to be provided to the Keystore record
    ///                              controller `authorize` method to perform authorization based on the L1 state.
    /// @param controllerProofs The `ControllerProofs` struct containing the necessary proofs to authorize the update.
    function set(
        bytes32 id,
        address account,
        ValueHashPreimages calldata currentValueHashPreimages,
        bytes32 newValueHash,
        ValueHashPreimages calldata newValueHashPreimages,
        bytes calldata l1BlockData,
        ControllerProofs calldata controllerProofs
    ) public {
        // Read the current ValueHash for the provided Keystore identifier.
        // If none is set, uses the identifier as the current ValueHash.
        bytes32 currentValueHash = records[id][account];
        if (currentValueHash == 0) {
            currentValueHash = id;
        }

        // Check if the `newValueHash` update is authorized.
        KeystoreLib.verifyNewValueHash({
            id: id,
            currentValueHash: currentValueHash,
            currentValueHashPreimages: currentValueHashPreimages,
            newValueHash: newValueHash,
            newValueHashPreimages: newValueHashPreimages,
            l1BlockData: l1BlockData,
            controllerProofs: controllerProofs
        });

        records[id][account] = newValueHash;

        emit KeystoreRecordSet({id: id, account: account, newValueHash: newValueHash});
    }
}
