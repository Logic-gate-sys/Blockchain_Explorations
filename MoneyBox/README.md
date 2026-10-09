Project structure: 
main contract:

 - MoniBox.sol
  MoniBox contains the main logics for : 

   1. allowing a group to indicate interest & enter a micro-saving-agreement ; 
     - they could indicate the total number of people needed in total or it could be open to as many as possible.  
     - they would specify late-penalty rate say 10%
     - they would indicate profit rate say 4%
     - they would incate penalty for loan default - choose from among other things as enum
     - they would indicate how much each individual should contribute
     - they would also specify the sharing date
   2. Storing securely groups and their members and using this to distribute saving and profits

   2. Use oracle to fetch real-price data to get actual price in dollars based on indicated contribution for each individual

   3. Check and perform upkeep with chainlink automations as follow:
     - distributing funds at the end of the saving term
     - check if nearest saving term has come && placing penalties on late / no contribution at all ( 5% for late and 25% for no payment)

   4. Giving out loans to members for a set profit rate: say 5%
        - loans have and agreed repayment duration which is decide by the team at the start
        - chainlink automations to check repayment on due time: 
           - implementing default penalty say : all saving held and loan + interest redacted

   5. Contract should acumulate: 
       - 2% of all transactions that comes throught the platform as service fee

























## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
