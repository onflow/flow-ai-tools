---
name: flow-dev-setup
description: |
  Guide for setting up a local Flow blockchain development environment from scratch. Covers installing and configuring the Flow CLI, emulator, dev wallet, Cadence VS Code extension, testing framework, frontend SDKs (FCL/React), and EVM tooling (Hardhat/Foundry). Each tool has its own reference with self-contained install and setup instructions.
  TRIGGER when: setting up Flow development tools, installing Flow CLI, starting emulator for the first time, "how do I install flow", "set up my dev environment", "flow dev setup", "install flow-cli", "cadence extension", "set up emulator", "flow testing setup", "FCL install", "EVM on Flow", "Hardhat with Flow", "Foundry with Flow", "new to Flow development", "getting started with Flow".
  DO NOT TRIGGER when: configuring flow.json or deployments (use flow-project-setup), writing Cadence code (use cadence-lang), querying on-chain data (use flow-cli-query), building token contracts (use cadence-tokens), auditing code (use cadence-audit).
---

# Flow Dev Environment Setup

Install and configure the tools needed for Flow blockchain development. Each reference below is self-contained — read only the ones relevant to your task.

## Tool Overview

| Tool | Purpose | Required? |
|------|---------|-----------|
| **Flow CLI** | Core tool — project init, contract deploy, transactions, testing, emulator | Yes — everything depends on this |
| **Flow Emulator** | Local Flow blockchain for development (bundled with CLI) | Yes — for local development |
| **Cadence VS Code Extension** | Syntax highlighting, code completion, type checking for `.cdc` files | Recommended for VS Code users |
| **Flow Testing Framework** | Cadence-native tests with coverage and fork testing | Yes — for writing/running tests |
| **Flow Dev Wallet** | Mock FCL-compatible wallet for local frontend auth testing | Only for frontend development |
| **FCL / React SDK** | Frontend libraries for wallet auth, transactions, and queries | Only for frontend development |
| **EVM Tooling** | Hardhat, Foundry, or Remix for Solidity development on Flow | Only for EVM/Solidity development |

## Navigation Map

| Task | Reference |
|------|-----------|
| Install Flow CLI (brew, script, Windows), verify, upgrade | [flow-cli.md](references/flow-cli.md) |
| Start and configure the Flow Emulator (ports, persistence, fork mode) | [emulator.md](references/emulator.md) |
| Install Cadence VS Code extension for editor support | [vscode-extension.md](references/vscode-extension.md) |
| Set up testing framework, run tests, coverage, fork testing | [testing.md](references/testing.md) |
| Set up dev wallet for local frontend auth testing | [dev-wallet.md](references/dev-wallet.md) |
| Install FCL or React SDK for frontend integration | [frontend-sdk.md](references/frontend-sdk.md) |
| Set up Hardhat, Foundry, or Remix for Solidity on Flow EVM | [evm-tooling.md](references/evm-tooling.md) |

## Typical Setup Order

For most Cadence projects: **Flow CLI** → **Emulator** → **VS Code Extension** → **Testing**.

Add **Dev Wallet** + **Frontend SDK** when building a frontend. Add **EVM Tooling** only for Solidity work.
