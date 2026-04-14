# Tokenomics First Principles

Economic and game-theory foundations for token design.

---

## Fisher Equation: MV = PQ

The quantity theory of money applied to token economics:

```
M = Money supply (circulating token supply)
V = Velocity (how often tokens change hands per period)
P = Price per token
Q = Quantity of economic activity (GDP equivalent for the protocol)
```

Rearranged: `P = (M × V) / Q` — **to increase P, increase Q or decrease V**.

### Velocity Reduction Strategies

| Strategy | Mechanism | Velocity reduction |
|----------|-----------|-------------------|
| **Staking** | Lock tokens → earn yield | High (locked supply exits float) |
| **Vesting cliff** | Founders/investors can't sell immediately | High (supply suppressed) |
| **NFT-gated utility** | Hold token → access features | Medium (incentivizes holding) |
| **Governance power** | Voting power increases with hold duration | Medium |
| **Sink mechanics** | Burns on each transaction | Medium (reduces M) |
| **Exit penalty** | Fee for early unstaking | Low-medium (discourages exit) |

**Common mistake:** Building demand without sinks. Every new use case increases Q (demand) but if it also increases velocity (people buy-use-sell), P can still fall.

---

## Nash Equilibrium Design

The goal: make "hold" the dominant strategy in the token's game theory.

### Why Olympus (3,3) Failed

Olympus claimed a Nash equilibrium where all players choosing to "bond" and "stake" (coded as "(3,3)") was optimal. It worked until it didn't:

| Condition | Holding optimal? |
|-----------|-----------------|
| APY > expected price decline | ✅ Yes — stake and collect yield |
| APY < expected price decline | ❌ No — sell now, buy back cheaper |
| Everyone thinks everyone will sell | ❌ Mass exit is rational → self-fulfilling |

**Result:** Olympus fell from $1,400 to $10 (-99%) because defection became rational when price momentum reversed. The "(3,3)" equilibrium was only stable in bull markets.

### Designing Stable Equilibria

A holding equilibrium is stable when:
1. **Holding provides real cash flow** — not just more tokens (which dilute)
2. **Exit has meaningful cost** — vesting cliff, time lock, or burned tokens on exit
3. **Network effects increase with holders** — more holders → more utility → more demand

**GMX model (stable, v1):**
- Hold GMX → receive 30% of protocol fees in ETH *(v1 mechanism; GMX v2, October 2024, replaced this with a buyback model)*
- Cash flow denominated in ETH (not GMX) — no reflexivity
- No exit penalty, but exiting means losing ongoing cash flow
- Equilibrium: hold GMX if you believe protocol will generate more fees

---

## Mechanism Design Principles

### 1. Sybil Resistance

| Method | Cost barrier | Time barrier | Social barrier |
|--------|-------------|--------------|----------------|
| Proof of Work | High (hardware) | High | None |
| Proof of Stake | High (capital) | Medium (lockup) | None |
| Social graph (Gitcoin Passport) | Medium | Medium | High |
| KYC | Low | Medium | High |
| Activity threshold | Low | High | None |

**For airdrop Sybil resistance:** Combine time (wallet age > 90 days) + activity (5+ transactions) + capital (held > $100 in protocol). Makes farming economically unviable for most attackers.

### 2. Anti-Gaming

Mechanisms break when rational actors optimize against them rather than for their stated purpose:

| Bad design | Gaming attack | Fix |
|------------|--------------|-----|
| Reward volume | Wash trading | Reward net volume or unique counterparties |
| Reward TVL | Borrow-and-deposit loop | Reward non-collateralized TVL only |
| Reward wallet count | Multi-wallet sybil | Social proof + activity threshold |
| Reward early users | Point farmers | Time-weighted + quality actions |

### 3. Long-Term Alignment Mechanisms

- **Vesting cliffs:** 6–12 month cliff + 2–3 year linear vest for founders/investors
- **Multiplier Points (GMX):** Stake longer → earn multiplier tokens → higher yield share (non-transferable, lost on unstake — punishes exit)
- **Time-weighted voting:** Quadratic increase in voting power with lock duration (reduces whale dominance for short-term holders)
- **Exit penalty redistribution:** Early unstake penalty → distributed to remaining stakers (creates positive externality from exits)

---

## Behavioral Economics

### Loss Aversion in Vesting Design

People feel losses 2× more intensely than equivalent gains (Kahneman-Tversky prospect theory). Apply to token mechanics:

- **Cliff as streak-loss:** Frame 12-month cliff as "you've earned X tokens — unstake before maturity and lose them all" rather than "you'll receive tokens after 12 months"
- **Sunk cost lock-in:** Once users have staked for 3+ months, the cliff loss-aversion keeps them locked
- **Progress bars:** Show "67% vested" not "4 more months" — the former triggers completion psychology

### Endowment Effect in Airdrops

People value things more once they own them. Airdrop mechanics:
- **Drop first, explain later:** Users who receive tokens and then learn what they're for are more engaged than users who research before receiving
- **Tiered revelation:** Reveal larger airdrop amounts in stages (build excitement and commitment)
- **Identity attachment:** "Your allocation reflects your contribution to X" — ties token to identity

### FOMO Mechanics

- **Scarcity:** Fixed supply, transparent burn rate, countdown to unlock cliff
- **Social proof:** Leaderboards, public staker counts, whale wallet tracking
- **Asymmetric upside framing:** "Only 500 wallets hold enough tokens for governance rights" (scarcity signal)

> **See also:** `design-patterns.md` for proven token models with real-world metrics. `value-accrual.md` for revenue-to-token mechanisms.
