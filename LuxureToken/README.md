
# 💎 LuxureToken

**LuxureToken** is a custom ERC-20-compatible smart contract written in Solidity, designed for testing and educational purposes. It demonstrates core token functionalities such as transfers, approvals, and allowance management, using Foundry for unit testing.

## 🚀 Features

* ✅ Token deployment with initial total supply
* 🔁 Transfer tokens between users
* 🔐 Approve and delegate spending with `approve` and `transferFrom`
* 📊 Allowance tracking for delegated transfers
* 📦 Extensive unit tests written using [Foundry](https://book.getfoundry.sh/)

## 🛠️ Tech Stack

* **Solidity** `^0.8.19`
* **Foundry** (Forge & Anvil)
* **forge-std** for testing utilities

## 📂 Project Structure

```
├── src/
│   └── LuxureToken.sol        # ERC-20 token logic
├── test/
│   └── LuxureTest.t.sol       # Unit tests
├── script/
│   └── DeployLuxure.s.sol     # Deployment script
├── foundry.toml               # Foundry config
```

##  Running Tests

```bash
forge test
```

## Test Coverage

The test suite includes:

* Token deployment and total supply
* Balance and transfer logic
* `approve`, `transferFrom`, and `allowance` behavior
* Event emission checks (`Transfer`, `Approval`)
* Edge cases and expected reverts

## 📄 License

MIT © 2025 Daniel Kpatamia

---

Let me know if you want badges, deployment instructions, or usage examples added.
