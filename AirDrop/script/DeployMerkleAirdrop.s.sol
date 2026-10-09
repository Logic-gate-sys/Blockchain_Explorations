//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {BengalToken} from "../src/BengalToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {Script} from "forge-std/Script.sol";
import {IERC20} from "../lib/openzepplin-contracts/contracts/interfaces/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    // lets stores state variables
    bytes32 merkle_root = 0xb7c59efa89f34e7107284e304a606e70baea4abaee71632cf75e311fad041968;
    BengalToken token;
    MerkleAirdrop airdrop;
    uint256 constant TOKENT_AMOUNT = 4 * 25 * 1e18;

    function run() public returns (BengalToken, MerkleAirdrop) {
        // broadcast all state chainging transactions to the blockchain
        vm.startBroadcast();
        //deploy contracts
        token = new BengalToken();
        airdrop = new MerkleAirdrop(merkle_root, IERC20(address(token)));
        //mint token amount to deployer
        token.mint(msg.sender, TOKENT_AMOUNT);
        // tranfer minted tokens to the air drop
        require(token.transfer(address(airdrop), TOKENT_AMOUNT), "Transfer failed");        // stop broadcast
        vm.stopBroadcast();

        //return contractss
        return (token, airdrop);
    }
}
