Upgradable smart-contracts
# Upgradable Smart Contracts

This repository demonstrates the use of upgradable smart contracts using [OpenZeppelin Contracts Upgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable) and [Foundry](https://github.com/foundry-rs/foundry). It provides example contracts, deployment scripts, and tests to help you get started with secure and maintainable upgradeable contract development.

## Features

- Example implementation of upgradeable contracts (`BoxV1`, `BoxV2`)
- Deployment and upgrade scripts using Foundry
- Automated tests for deployment and upgrade flows
- Integration with OpenZeppelin's upgradeable libraries

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/) (for `forge` and `cast`)
- [Git](https://git-scm.com/)

### Installation

Clone the repository and install dependencies:

```sh
git clone https://github.com/your-username/upgradable_contract.git
cd upgradable_contract
forge install
* Compile Contracts
forge build
* Run Tests
forge test
** Deploy and Upgrade
* Deployment and upgrade scripts are located in the script/ directory:
* DeployBox.s.sol: Deploys the initial version of the contract.
* UpgradeBox.sol: Upgrades the contract to a new version.
* You can run these scripts using Foundry's forge script command.

src/        # Solidity contract sources
script/     # Deployment and upgrade scripts
test/       # Test contracts
lib/        # External dependencies (OpenZeppelin, Forge Std, etc.)

*References
** OpenZeppelin Contracts Upgradeable Documentation
** Foundry Book
** License
** This project is licensed under the MIT License.

