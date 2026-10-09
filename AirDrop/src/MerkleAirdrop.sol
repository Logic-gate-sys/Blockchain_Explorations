//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20, SafeERC20} from "../lib/openzepplin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



/**
 * @title Merkle Air Drop
 * @author Daniel Kwasi Kpatamia
 * @notice Merkle proof implements cryptographic proofs using merkle trees data structures to verify if an address can claim a token
 * @dev This is the gate way to the air-drop functionality
 */
contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;
    //---------------------errors----------------------------

    error MerkleAirdrop_InvalidProof();
    error MerkleAirdrop_AlreadyClaimed();
    error MerkleAirdrop_InvalidSignature();

    //-------------- state variables ---------------------------
    IERC20 private s_token;
    bytes32 private s_merkleRoot;
    mapping(address user => bool hasClaimed) private s_hasClaimed;
    bytes32 private constant MESSAGE_TYPEHASH = 0x810786b83997ad50983567660c1d9050f79500bb7c2470579e75690d45184163;

    //------------------ event --------------------------------
    event Claim(address indexed user, uint256 amount);

    /**
     * @param _root: root of the offchain merkle data corresponding to all claimants and the amount they can claim
     * @param _tokenAddress: address of the ERC20 token that would be airdroped
     * @notice :constractor intialises these two at run-time
     */
    constructor(bytes32 _root, IERC20 _tokenAddress) EIP712("MerkleAirdrop", "1.0.1") {
        s_token = _tokenAddress;
        s_merkleRoot = _root;
    }

    /**
     * @param account: address trying to make claim
     * @param amount : amount the address is trying to claim
     * @param  merkle_proof: the calldata array of proof to show that address and amount qualifies a user
     * @notice claim function determines if a user is eligible for token airdrop
     * Then entire list of eligible users is hased
     * merkle proofs are served to each eligible address(user) that users can use to claim their tokens to reduce gas
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkle_proof, uint8 v, bytes32 s, bytes32 r)
        external
    {
        //checks
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop_AlreadyClaimed();
        }
        //----------- signature  check -------------
        bytes32 digest = getMessageHash(account, amount);
        if (!_isValidSignature(account, digest, v, s, r)) {
            revert MerkleAirdrop_InvalidSignature();
        }
        //double hashing prevent second-pre-image attacks where a hacker might find inputs that produces the same hash there by claiming falsely
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        //verify users proof against merkle root
        if (!MerkleProof.verify(merkle_proof, s_merkleRoot, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }
        //Effects
        s_hasClaimed[account] = true;
        // emit Claim
        emit Claim(account, amount);
        //Interaction
        // safe transfer underlying token
        s_token.safeTransfer(account, amount);
    }

    //struct
    struct AirDropParams {
        address account;
        uint256 amount;
    }

    //return the bytes32 message hash compatible with EIP721
    function getMessageHash(address account, uint256 amount) public returns (bytes32) {
        bytes32 hash =
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirDropParams({account: account, amount: amount}))));
        return hash;
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 s, bytes32 r)
        internal
        pure
        returns (bool)
    {
        (address recovered,,) = ECDSA.tryRecover(digest, v, r, s);
        return recovered == account;
    }
    // -------------------- getters ,public and view functions ----------------------------------------------------

    function getMerkleRoot() public view returns (bytes32) {
        return s_merkleRoot;
    }

    function getAirdropToken() public view returns (IERC20) {
        return s_token;
    }
}
