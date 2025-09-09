# L3Token

**L3Token** is an ERC-20 compatible token built in Solidity, designed as the base layer for future features such as staking, reward distribution, and modular extensions. This project serves as both a learning exercise and a foundation for building more advanced tokenized applications.

---

## ✨ Features

- ✅ **ERC-20 Standard** — Implements the ERC-20 interface for interoperability across wallets, dApps, and exchanges.
- ✅ **Minting Controls** — Only authorized addresses can mint new tokens.
- ✅ **Staking Support** — A companion staking contract lets users lock tokens and earn rewards over time.
- ✅ **Role Management** — Supports modular role assignment for features like staking and reward distribution.
- ✅ **Upgradeable Design** — Built with modularity in mind so new features can be layered on top.

---

## 🏗️ Architecture

The project consists of two main components:

1. **L3Token (ERC-20)** — Core token contract with standard functionality plus restricted minting.
2. **L3Staker (Staking Contract)** — Handles staking/unstaking logic and calculates rewards based on stake duration.

---

## 📜 Contracts

- `src/L3Token.sol` — Core ERC-20 token contract.
- `src/L3Staker.sol` — Staking contract that interacts with `L3Token`.

---

## ⚡ Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/) installed
- Node.js (optional, if interacting with frontends)
- An RPC provider (e.g. [Alchemy](https://alchemy.com) or [Infura](https://infura.io))

### Setup

```bash
git clone https://github.com/yourusername/L3Token.git
cd L3Token
forge install

Create a .env file and set:

RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
PRIVATE_KEY=0xyourprivatekey
ETHERSCAN_API_KEY=yourapikey

Deploy
forge script script/L3Token.s.sol:L3TokenScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --chain-id 11155111

🧪 Testing

Run tests with:

forge test -vvv


The test suite includes:

Unit tests for ERC-20 logic.

Staking/unstaking scenarios.

Reward accrual simulation using vm.warp for time travel.

🔮 Roadmap

 Add governance module

 Expand staking to support multiple reward tokens

 Integrate upgradeable proxy support

 Security audits and fuzz testing

📖 License

MIT License. Free to use, modify, and distribute.


```
