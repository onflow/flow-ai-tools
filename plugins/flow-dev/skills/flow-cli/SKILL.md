---
name: flow-cli
description: |
  Complete reference for the Flow CLI — the command-line tool for developing, testing, and deploying on the Flow blockchain. Covers project initialization, account management, contract deployment, transaction sending, script execution, dependency management, key generation, scheduled transactions, and emulator usage.
  TRIGGER when: using the Flow CLI, running flow commands, "flow accounts get", "flow accounts create", "flow init", "flow project deploy", "flow scripts execute", "flow transactions send", "flow test", "flow emulator", "flow keys generate", "flow dependencies install", "flow schedule", "flow accounts fund", "deploy contract to testnet", "how to create a Flow account", "check account balance on Flow", "run cadence script", "send a transaction", "flow accounts add-contract", "flow accounts staking-info".
  DO NOT TRIGGER when: writing Cadence contract code (use cadence-lang), building React frontends (use flow-react-sdk), composing DeFi transactions in Cadence (use cadence-defi-actions), auditing code (use cadence-audit).
---

# Flow CLI

The Flow CLI manages the full development lifecycle: project setup, account management, contract deployment, transaction sending, script execution, and local testing.

## Quick Start

```bash
flow init my-project     # Initialize project
flow emulator            # Start local emulator
flow project deploy      # Deploy contracts
flow test                # Run tests
```

## Navigation Map

| Task | Reference |
|------|-----------|
| Full command list, global flags, output options | [commands-overview.md](references/commands-overview.md) |
| Account commands: get, create, fund, staking, contracts | [accounts.md](references/accounts.md) |
| Project commands: init, generate, deploy, test, deps, config | [project.md](references/project.md) |

## Key Principles

- Default network is `emulator` — always specify `--network testnet` or `--network mainnet` for non-local operations
- Use `--output json` when parsing output programmatically
- Account names resolve via `flow.json` — use addresses directly when no config is present
- Flow addresses accept both `0x`-prefixed and raw hex formats

## Companion Skills

- **`cadence-lang`** — Consult when writing Cadence scripts for `flow scripts execute` or transactions for `flow transactions send`. The Cadence code must follow all language rules for access control, entitlements, and resource handling.
- **`flow-project-setup`** — Consult for `flow.json` configuration, deployment strategies, and the overall development workflow that ties CLI commands together.
- **`cadence-scaffold`** — Use to generate contracts and transactions before deploying them with the CLI.
- **`cadence-audit`** — Use to review contracts before deploying with `flow project deploy` or `flow accounts add-contract`.
