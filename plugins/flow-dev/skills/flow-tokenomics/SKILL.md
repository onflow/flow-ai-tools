---
name: flow-tokenomics
description: |
  Framework for designing token economics for Flow-based protocols. Covers economic first principles (Fisher Equation MV=PQ, Nash equilibrium, mechanism design, behavioral economics), proven design patterns with metrics (Real Yield/GMX, Buyback/Hyperliquid, veToken/Curve) and failure case studies (Olympus, Terra, Anchor), token value accrual mechanisms, TGE launch playbook with 12-week timeline, DAO governance models and attack vectors, and regulatory compliance (Howey Test, SEC precedents, MiCA, tax treatment).
  TRIGGER when: designing token mechanics, token value accrual, token launch strategy, DAO governance design, veToken model, buyback vs burn vs real yield, Howey Test analysis, token vesting design, anti-Sybil strategy, tokenomics for a protocol, token distribution, staking design, governance attack vectors, securities compliance, TGE planning, points programs, airdrop design, "what token model should I use", "is my token a security".
  DO NOT TRIGGER when: designing DeFi protocol architecture (use flow-defi), writing Cadence token contracts (use cadence-tokens), FT/NFT interface standards (use cadence-tokens).
---

# Flow Tokenomics

Design token economics for Flow-based protocols — from first principles through launch strategy, governance, and regulatory considerations.

## Navigation Map

| Task | Reference |
|------|-----------|
| Economic foundations: Fisher Equation, Nash equilibrium, mechanism design, behavioral economics | [first-principles.md](references/first-principles.md) |
| Pattern library: 5 proven patterns with metrics, 5 anti-patterns with failures, supply design | [design-patterns.md](references/design-patterns.md) |
| Revenue-to-token mechanisms: real yield, buyback/burn, P/E framework, Howey Test by mechanism | [value-accrual.md](references/value-accrual.md) |
| TGE playbook: 12-week timeline, distribution options, failure archive, market psychology | [launch-strategy.md](references/launch-strategy.md) |
| DAO governance models, attack vectors, defenses, regulatory compliance | [governance-compliance.md](references/governance-compliance.md) |

## Key Principles

1. **Velocity kills price** — High token velocity (fast rotation through wallets) suppresses price; sinks and lock-ups reduce velocity
2. **Emissions without demand is poison** — Incentive programs must create real demand, not just TVL that exits when emissions end
3. **Real yield > narrative** — Protocols generating actual revenue and sharing it survive market cycles; those relying on emissions alone don't
4. **Lock-up or lose** — Programs without lock-up lose 60–80% of participants within 30 days of incentives ending
5. **Deflationary mechanics require revenue** — Burns only work long-term if protocol revenue sustains or exceeds emission rate

## Companion Skills

- **`flow-defi`** — Use alongside when the token is for a DeFi protocol. Liquidity bootstrapping, veFLOW mechanics, and ecosystem positioning decisions affect tokenomics design.
- **`cadence-tokens`** — Use when implementing the actual FT/NFT contracts for the token. This skill covers economic design; cadence-tokens covers Cadence implementation.
- **`cadence-audit`** — Audit token contracts (staking, vesting, governance) before deployment.
