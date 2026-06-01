# PortoToken (PORTO) — ERC-20 Smart Contract

![Solidity](https://img.shields.io/badge/Solidity-^0.8.28-363636?logo=solidity)
![Foundry](https://img.shields.io/badge/Built%20with-Foundry-orange?logo=ethereum)
![License](https://img.shields.io/badge/License-MIT-green)
![CI](https://img.shields.io/badge/CI-GitHub%20Actions-blue?logo=githubactions)

> A fully hand-written ERC-20 fungible token smart contract built from scratch in Solidity — without any third-party library like OpenZeppelin — complete with unit tests, fuzz tests, integration tests, and an automated CI/CD pipeline.

---

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Smart Contract Architecture](#smart-contract-architecture)
  - [PortoToken](#porttoken-contract)
  - [Ownable](#ownable-contract)
  - [IERC20 Interface](#ierc20-interface)
- [Token Details](#token-details)
- [Contract Functions](#contract-functions)
- [Custom Errors](#custom-errors)
- [Events](#events)
- [Security Considerations](#security-considerations)
- [Test Coverage](#test-coverage)
- [CI/CD Pipeline](#cicd-pipeline)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Free Smart Contract Audit Tools](#free-smart-contract-audit-tools)

---

## Overview

**PortoToken (PORTO)** is an ERC-20 compliant fungible token written entirely in Solidity without relying on any external libraries such as OpenZeppelin. This project was built to demonstrate a deep understanding of the ERC-20 standard, Solidity smart contract development, access control patterns, and professional testing practices using the Foundry framework.

Key highlights:
- Pure Solidity implementation — no OpenZeppelin dependency
- Custom `Ownable` access control contract
- Custom `IERC20` interface definition
- Comprehensive test suite: unit tests, fuzz tests, and integration scenarios
- GitHub Actions CI/CD pipeline for automated build and test checks
- Gas-efficient `custom errors` instead of `require` strings

---

## Project Structure

```
smart-contract/
├── src/
│   ├── ERC20.sol           # Main token contract (PortoToken, IERC20, Ownable)
│   └── Counter.sol         # Foundry default scaffold (unused in production)
├── test/
│   ├── ERC20.t.sol         # Full test suite for PortoToken
│   └── Counter.t.sol       # Foundry default scaffold
├── script/
│   ├── ERC20.s.sol         # Deployment script for PortoToken
│   └── Counter.s.sol       # Foundry default scaffold
├── lib/
│   └── forge-std/          # Foundry standard library (submodule)
├── out/                    # Compiled artifacts (auto-generated)
├── cache/                  # Foundry build cache (auto-generated)
├── .github/
│   └── workflows/
│       └── test.yml        # GitHub Actions CI pipeline
├── foundry.toml            # Foundry configuration
└── README.md
```

---

## Tech Stack

| Technology | Version | Purpose |
|---|---|---|
| **Solidity** | `^0.8.28` | Smart contract language |
| **Foundry / Forge** | Latest | Build, test, and deployment framework |
| **forge-std** | Submodule | Testing utilities (Test, vm, assertions) |
| **GitHub Actions** | — | CI/CD pipeline automation |
| **EVM** | — | Target execution environment |

**Why Foundry?**
Foundry is a blazing-fast, Rust-based Ethereum development framework. Compared to Hardhat (JavaScript), Foundry runs tests entirely in Solidity, making tests closer to on-chain behavior, faster to execute, and simpler to write — especially for fuzz testing.

---

## Smart Contract Architecture

### PortoToken Contract

The core token contract. It inherits `Ownable` for access control and implements `IERC20` for standard token behavior.

```
PortoToken
├── Inherits: Ownable
├── Implements: IERC20
├── State Variables:
│   ├── name         → "PortoToken"
│   ├── symbol       → "PORTO"
│   ├── decimals     → 18
│   ├── totalSupply  → 1,000,000 PORTO
│   ├── balances     → mapping(address => uint256)   [private]
│   └── allowances   → mapping(address => mapping(address => uint256))   [private]
└── Functions: balanceOf, transfer, approve, allowance, transferFrom, mint, burn
```

### Ownable Contract

A lightweight, custom access control contract. Instead of inheriting from OpenZeppelin, this contract is written manually to demonstrate understanding of ownership patterns.

```solidity
contract Ownable {
    address public immutable owner;  // Set once at deployment, cannot change
    modifier onlyOwner();            // Restricts function access to the deployer
}
```

`owner` is declared as `immutable` — this is a gas optimization that bakes the value directly into the contract bytecode at deploy time, avoiding a storage read on every `onlyOwner` check.

### IERC20 Interface

Defines the standard ERC-20 function signatures that `PortoToken` must implement. Writing this manually demonstrates understanding of the interface pattern and the EIP-20 specification.

---

## Token Details

| Property | Value |
|---|---|
| **Name** | PortoToken |
| **Symbol** | PORTO |
| **Decimals** | 18 |
| **Initial Supply** | 1,000,000 PORTO |
| **Minting** | Owner only |
| **Burning** | Any token holder |

---

## Contract Functions

### `balanceOf(address account) → uint256`
Returns the token balance of `account`. Reverts with `InvalidAddress` if `account` is the zero address.

### `transfer(address to, uint256 amount) → bool`
Transfers `amount` tokens from `msg.sender` to `to`. Reverts on zero address or insufficient balance. Emits `Transfer`.

### `approve(address spender, uint256 amount) → bool`
Allows `spender` to spend up to `amount` tokens from `msg.sender`'s balance. Emits `Approval`.

### `allowance(address owner, address spender) → uint256`
Returns the remaining amount that `spender` is allowed to spend on behalf of `owner`. Validates both addresses.

### `transferFrom(address from, address to, uint256 amount) → bool`
Transfers `amount` from `from` to `to` using `msg.sender`'s allowance. Decrements allowance upon success. Reverts on zero addresses, insufficient balance, or insufficient allowance. Emits `Transfer`.

### `mint(address to, uint256 amount)` *(onlyOwner)*
Mints new tokens and sends them to `to`. Increases `totalSupply`. Reverts if caller is not the owner, `to` is zero address, or `amount` is zero. Emits `Transfer(address(0), to, amount)`.

### `burn(uint256 amount)`
Burns `amount` tokens from `msg.sender`'s balance. Decreases `totalSupply`. Reverts if `amount` is zero or caller has insufficient balance. Emits `Transfer(msg.sender, address(0), amount)`.

---

## Custom Errors

This contract uses **custom errors** instead of `require` strings. Custom errors are more gas-efficient because error data is not stored as strings in the bytecode, and they provide structured revert reasons.

| Error | Triggered When |
|---|---|
| `InvalidAddress()` | A zero address (`address(0)`) is passed where it is not allowed |
| `NotEnoughtAmount()` | Caller's token balance is less than the requested transfer/burn amount |
| `NotEnoughtAllowance()` | `transferFrom` caller's allowance is less than the requested amount |
| `ZeroAmount()` | A zero value is passed to `mint` or `burn` |
| `NotOwner()` | A non-owner address attempts to call an `onlyOwner` function |

---

## Events

| Event | Emitted When |
|---|---|
| `Transfer(address indexed from, address indexed to, uint256 amount)` | Tokens are transferred, minted (`from = address(0)`), or burned (`to = address(0)`) |
| `Approval(address indexed owner, address indexed spender, uint256 amount)` | An allowance is set via `approve` |

---

## Security Considerations

This contract was written with security best practices in mind:

**Checks-Effects-Interactions (CEI) Pattern**
All state-changing functions follow the CEI pattern: validation checks are performed first, state variables are updated next, and external interactions (events) are emitted last — mitigating potential reentrancy risks.

**No Integer Overflow**
Solidity `^0.8.x` includes built-in overflow/underflow protection by default. All arithmetic operations revert automatically on overflow or underflow.

**Immutable Owner**
The `owner` address is declared `immutable`. Once set in the constructor, it cannot be changed, eliminating any risk of ownership takeover through a setter function.

**Zero Address Validation**
All critical functions validate against the zero address (`address(0)`) to prevent token loss through accidental or malicious burns to an unrecoverable address.

**Private State Variables**
`balances` and `allowances` mappings are declared `private`. External parties can only read them through the public getter functions (`balanceOf`, `allowance`), preventing direct storage manipulation.

**Custom Errors over `require` Strings**
Custom errors use less gas and provide more structured revert data — benefiting both end users and tooling.

**Known Limitation — No `increaseAllowance` / `decreaseAllowance`**
The contract implements the minimal ERC-20 standard without `increaseAllowance`/`decreaseAllowance` helpers. This means a classic ERC-20 front-running attack on `approve` is theoretically possible (a spender can race to spend the old allowance before the new one is set). In production, this is typically mitigated by resetting the allowance to `0` before setting a new non-zero value — a pattern demonstrated in the test suite (`test_Approve_ZeroResetsAllowance`).

---

## Test Coverage

The test suite (`test/ERC20.t.sol`) contains **47 tests** organized into the following categories:

### Deploy / Constructor Tests
Verify that the contract deploys correctly with the expected name, symbol, decimals, total supply, initial owner balance, and ownership.

### `balanceOf` Tests
- Returns correct balance for existing addresses
- Reverts with `InvalidAddress` on zero address query

### `transfer` Tests
- Successful transfer with balance/event assertions
- Reverts on zero address destination
- Reverts on insufficient balance
- Full balance transfer
- Zero-amount transfer (ERC-20 allows this)
- Self-transfer (balance unchanged)
- **Fuzz test**: randomized amount within `[0, INITIAL_SUPPLY]`

### `approve` & `allowance` Tests
- Successful approval with event assertion
- Reverts on zero spender address
- Reverts on zero owner/spender in `allowance`
- Default allowance is zero
- Overwriting an existing allowance
- Resetting allowance to zero

### `transferFrom` Tests
- Full success path with allowance decrement
- Reverts on zero `to` address
- Reverts on zero `from` address
- Reverts on insufficient balance
- Reverts on insufficient allowance
- Correct allowance decrement after partial spend

### `mint` Tests
- Successful mint with event and supply assertions
- Reverts on zero address recipient
- Reverts on zero amount
- Increases `totalSupply` correctly
- Reverts if caller is not owner
- Emits `Transfer(address(0), to, amount)` correctly
- **Fuzz test**: randomized amount within `[1, type(uint128).max]`

### `burn` Tests
- Successful burn with event and supply assertions
- Reverts on insufficient balance
- Reverts on zero amount
- Full balance burn (supply goes to zero)
- Decreases `totalSupply` correctly
- **Fuzz test**: randomized amount within `[1, INITIAL_SUPPLY]`

### Integration / Scenario Tests
| Test | Description |
|---|---|
| `test_Integration_MintTransferBurn` | Full lifecycle: mint to alice → alice transfers to bob → bob burns |
| `test_Integration_ApproveAndTransferFrom` | Owner approves alice → alice calls `transferFrom` on behalf of owner |
| `test_Integration_MultipleTransfers` | Owner distributes tokens to three addresses in a single block |
| `test_Integration_BurnReducesTotalSupplyNotOthers` | Burning only affects `totalSupply` and the burner's balance, not other holders |

### Running the Tests

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run a specific test
forge test --match-test test_Mint_Success -vvv

# Run fuzz tests only
forge test --match-test testFuzz -vvv
```

---

## CI/CD Pipeline

The project includes a GitHub Actions workflow (`.github/workflows/test.yml`) that automatically runs on every `push` and `pull_request` to any branch.

**Pipeline Steps:**

```
1. Checkout repository (with submodules)
       ↓
2. Install Foundry toolchain
       ↓
3. Show Forge version
       ↓
4. forge fmt --check     → Enforce consistent code formatting
       ↓
5. forge build --sizes   → Compile contracts and display bytecode sizes
       ↓
6. forge test -vvv       → Run the full test suite with verbose output
```

This ensures that every commit is verified to compile cleanly, pass formatting checks, and pass all tests before it can be merged.

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installation

```bash
# Clone the repository
git clone https://github.com/fardann-arbazz/ERC20---PortoToken.git
cd smart-contract

# Install dependencies (forge-std submodule)
forge install
```

### Build

```bash
forge build
```

### Test

```bash
forge test -vvv
```

### Format

```bash
forge fmt
```

---

## Deployment

The deployment script is located at `script/ERC20.s.sol`. It uses Foundry's `Script` contract with `vm.startBroadcast()` / `vm.stopBroadcast()` to sign and send the deployment transaction.

```bash
# Deploy to a local Anvil node
anvil  # start local node in a separate terminal

forge script script/ERC20.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to a public testnet (e.g., Sepolia)
forge script script/ERC20.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

> **Never commit your private key.** Use environment variables or a `.env` file that is included in `.gitignore`.

---

## Free Smart Contract Audit Tools

Before deploying to mainnet, it is strongly recommended to run your contract through one or more of these free static analysis and audit tools:

### Static Analysis

| Tool | How to Use | What It Finds |
|---|---|---|
| **[Slither](https://github.com/crytic/slither)** | `pip install slither-analyzer` → `slither src/ERC20.sol` | Reentrancy, unchecked calls, access control issues, common bugs |
| **[Mythril](https://github.com/Consensys/mythril)** | `pip install mythril` → `myth analyze src/ERC20.sol` | Symbolic execution — finds integer overflow, reentrancy, tx.origin misuse |
| **[Aderyn](https://github.com/Cyfrin/aderyn)** | `cargo install aderyn` → `aderyn .` | Rust-based Foundry-aware analyzer with a markdown report output |

### Browser-Based Auditing

| Tool | URL | Notes |
|---|---|---|
| **Remix IDE + Solidity Analyzer** | [remix.ethereum.org](https://remix.ethereum.org) | Built-in static analysis plugin, free, no setup |
| **SpearBit / Solodit** | [solodit.xyz](https://solodit.xyz) | Browse past public audit reports for patterns similar to your code |

### Recommended First Step

Run **Slither** as it has the best Foundry integration and produces the most actionable output for contracts of this size:

```bash
pip install slither-analyzer
slither src/ERC20.sol --solc-remaps "@=lib/"
```

### Formal Verification (Advanced)

- **[Certora Prover](https://www.certora.com/)** — Free for open-source projects; write formal specs to mathematically prove contract behavior
- **[Halmos](https://github.com/a16z/halmos)** — Symbolic testing directly inside Foundry; finds edge cases fuzz testing may miss

---

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE) for details.
