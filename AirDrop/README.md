# Merkle Airdrop

A Solidity implementation of a token airdrop system using Merkle trees for efficient and gas-optimized token distribution.

## Overview

This project implements a token airdrop mechanism using Merkle proofs for validation. It includes:

- A custom ERC20 token ([`BengalToken.sol`](src/BengalToken.sol))
- Merkle-based airdrop contract ([`MerkleAirdrop.sol`](src/MerkleAirdrop.sol))
- Scripts for generating Merkle trees and proofs
- Comprehensive test suite

## Features

- Gas-efficient token distribution using Merkle proofs
- Automated scripts for generating Merkle trees from input data
- Integration with OpenZeppelin's Merkle tree implementation
- Foundry-based testing and deployment

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)
- [Node.js](https://nodejs.org/) (for scripts)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/merkle_airdrop
cd merkle_airdrop

## install dependencies
forge install
## generate sample input data
forge script script/GenerateInput.s.sol
## return output data 
forge script script/MakeMurkle.s.sol
## tests 
forge test

## Project Structure
src: Smart contracts
BengalToken.sol: ERC20 token implementation
MerkleAirdrop.sol: Airdrop contract using Merkle proofs
script: Deployment and setup scripts
test: Test files
License
This project is licensed under MIT.

## Acknowledgements
OpenZeppelin Contracts
Murky - Merkle proof utilities
Foundry
