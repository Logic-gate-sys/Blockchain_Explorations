# Rebase Token Protocol

## Overview

This protocol enables users to deposit an underlying asset (such as ETH or a stablecoin like WETH) into a central smart contract, referred to as the **Vault**. In return, users receive **rebase tokens** that represent their proportional share of the total underlying assets held within the Vault, including any accrued interest or rewards.

## Key Features

### Dynamic Balances

- The `balanceOf(address user)` function, following the ERC20 standard, returns a **dynamic value**. User balances increase over time, reflecting their share of accrued interest or rewards.
- The increase in balance is calculated **linearly with time** in this implementation.
- Importantly, `balanceOf` is a **view function**—it does not trigger state changes or mint new tokens on each call, ensuring **gas efficiency**.

### State Updates on Interaction

- Accrued interest is **minted** and user balances are updated **only** when a user performs a state-changing action, such as:
  - Depositing additional assets (minting more rebase tokens)
  - Withdrawing or redeeming assets (burning rebase tokens)
  - Transferring rebase tokens
  - (Future) Bridging tokens to another chain
- Before executing any of these actions, the contract calculates and mints the interest accrued since the user’s last interaction, updating their on-chain balance before proceeding.

## Interest Rate Mechanism

- The protocol features a **global interest rate**, managed by an owner or governance mechanism, which determines the base rate for interest accrual.
- **Decreasing Global Rate:** The global interest rate can **only decrease** over time; it cannot be increased once set.
- **User-Specific Interest Rate Snapshot:** On a user’s first deposit, the contract snapshots the current global interest rate, which becomes the fixed rate for that deposit.
- **Incentivizing Early Adopters:** Early users lock in higher interest rates, as subsequent deposits use the (potentially lower) global rate at the time of deposit.
- **Multiple Deposits:** Additional deposits by the same user accrue interest based on the prevailing global rate at the time of each deposit. The handling of multiple deposits and associated rates will be detailed in the contract implementation.

## Yield Source

While the Vault’s underlying assets could be deployed in DeFi strategies (e.g., staking, lending, liquidity provision) to generate yield, in this initial version, the "interest" is primarily a function of the rebase mechanism itself, designed to incentivize adoption by rewarding holders with additional tokens.

---

## Known Vulnerabilities

1. **Interest Rate Lock-In:** When a user makes an initial deposit and later deposits additional amounts, their original (potentially higher) interest rate is applied to all holdings, granting early adopters disproportionate benefits.
2. **Compounding Interest:** Since interest is derived by multiplying a growth factor with `balanceOf()`, the system compounds interest rather than accumulating it linearly.

---

*This document is a work in progress. Please review and contribute to ongoing discussions regarding protocol design and