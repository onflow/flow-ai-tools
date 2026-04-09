---
name: cadence-scaffold
description: |
  Generate production-ready Cadence smart contracts, transactions, and DeFi transactions from scratch following security-first standards. Scaffolds secure code with proper access control, entitlements, events, storage paths, and phase discipline.
  TRIGGER when: creating new Cadence contracts, generating transactions, scaffolding DeFi transactions, building smart contracts from scratch, "generate contract", "create transaction", "scaffold", "new contract", "new transaction", "build a contract for", "write me a contract", "help me create a", "template for", "boilerplate", "starter contract", "create an NFT contract", "generate a transfer transaction".
  DO NOT TRIGGER when: reviewing or auditing existing code (use cadence-audit), asking about Cadence syntax or language rules (use cadence-lang), configuring flow.json (use flow-project-setup).
---

# Cadence Code Scaffold

Generate production-ready Cadence contracts, transactions, and DeFi transactions following security-first standards.

## Scaffold Types

Determine what the user needs and follow the appropriate reference:

| What to generate | Reference |
|-----------------|-----------|
| Smart contract (NFT, FT, general, admin) | [scaffold-contract.md](references/scaffold-contract.md) |
| Transaction (transfer, setup, mint, multi-sig) | [scaffold-transaction.md](references/scaffold-transaction.md) |
| DeFi Actions transaction (restake, swap, auto-balance) | [scaffold-defi.md](references/scaffold-defi.md) |

## General Principles

All generated code must follow:
1. `access(self)` by default for all fields/functions
2. Entitlements for all privileged operations
3. String-based imports (`import "ContractName"`)
4. Descriptive panic messages with interpolated values
5. Events for significant state changes
6. Complete `init()` with all state initialized

For full language rules, reference the `cadence-lang` skill.
