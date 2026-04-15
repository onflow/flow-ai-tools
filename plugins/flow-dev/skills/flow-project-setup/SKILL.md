---
name: flow-project-setup
description: |
  Guide for setting up and configuring Flow blockchain projects. Covers flow.json structure (networks, accounts, contracts, dependencies, deployments), FCL frontend integration with React, Flow CLI workflow, emulator setup, testnet/mainnet deployment, environment-based configuration, and multi-network strategies.
  TRIGGER when: setting up a Flow project, configuring flow.json, setting up FCL, deploying contracts, switching networks, debugging deployment issues, "flow init", "flow emulator", "flow project deploy", "flow.json", "FCL config", "testnet deploy", "mainnet deploy", "contract deployment", "network configuration", "flow dependencies install", "emulator setup", "how to deploy to testnet", "configure FCL with React".
  DO NOT TRIGGER when: writing Cadence code or asking about syntax (use cadence-lang), building token contracts (use cadence-tokens), generating new contracts (use cadence-scaffold), auditing code (use cadence-audit).
---

# Flow Project Setup

Configure and deploy Flow projects across emulator, testnet, and mainnet.

## Quick Start

```bash
flow init              # Initialize project
flow emulator          # Start emulator
flow project deploy    # Deploy contracts
flow test              # Run tests
```

## Navigation Map

| Task | Reference |
|------|-----------|
| flow.json, FCL config, contract addresses, dependencies, CLI commands | [configuration.md](references/configuration.md) |
| Dev workflow, deployment, debugging, gas optimization, testnet validation | [workflow.md](references/workflow.md) |

## Companion Skills

- **`cadence-lang`** — Consult for Cadence language rules when debugging contract compilation errors or transaction failures. Understanding access control and resource handling is essential for diagnosing deployment issues.
- **`flow-cli`** — Consult for detailed CLI command syntax, flags, and account management operations used during the development workflow.
- **`flow-react-sdk`** — Consult when integrating the deployed project with a React frontend via FCL.
- **`cadence-audit`** — Run an audit before deploying to testnet/mainnet as part of the validation checklist.
