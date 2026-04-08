---
name: cadence-defi-actions
description: |
  Guide for composing DeFi transactions using the DeFiActions framework on Flow. Covers Source, Sink, Swapper, and SwapSource interfaces, IncrementFi staking/pool connectors, Zapper for LP token conversion, AutoBalancer for threshold-based rebalancing, and transaction templates for restaking and auto-balancing workflows.
  TRIGGER when: writing DeFi transactions, using DeFiActions connectors, composing Source/Sink/Swapper chains, restaking rewards, auto-balancing, "claim and restake", "stake rewards", "LP tokens", "swap and deposit", "DeFiActions", "SwapSource", "PoolSink", "PoolRewardsSource", "Zapper", "IncrementFi", "pool liquidity", "autobalancer", "connector composition".
  DO NOT TRIGGER when: asking about general Cadence syntax (use cadence-lang), building NFT/FT contracts (use cadence-tokens), setting up flow.json (use flow-project-setup), auditing code (use cadence-audit), querying blockchain data (use flow-cli-query).
---

# DeFi Actions Framework

Compose safe, correct Cadence transactions using DeFiActions connectors. Keep generations minimal, typed, and verifiable.

## Core Concepts
- **Source**: Provides tokens via `withdrawAvailable(maxAmount:)`
- **Sink**: Accepts tokens via `depositCapacity(from:)`
- **Swapper**: Converts tokens; `swap`, `swapBack`, `quoteIn/quoteOut`
- **SwapSource**: Combines Source + Swapper for automatic conversion

## Quick Start (Restake Rewards)
Claim → Zap → Stake: Read [workflows.md](references/workflows.md) for complete template.

## Navigation Map

| Task | Reference |
|------|-----------|
| Core interfaces (Source, Sink, Swapper, Quote, AutoBalancer) | [framework.md](references/framework.md) |
| Connector APIs and composition patterns | [connectors.md](references/connectors.md) |
| Safety rules, testing, checklist | [safety-testing.md](references/safety-testing.md) |
| Restaking and autobalancer workflows | [workflows.md](references/workflows.md) |
| Transaction templates and AI generation guide | [templates.md](references/templates.md) |

For any DeFi transaction, always read `safety-testing.md` for invariants.
