# Liquidity Strategy

Bootstrapping and sustaining liquidity for DeFi protocols on Flow.

---

## Bootstrapping Benchmarks

### Gold Standard: Base/Aerodrome
- Protocol-owned liquidity seeded at launch (reported ~$4M — verify exact figure)
- Reached $1B+ TVL by month 13 (late 2023); stabilized in the $500M–$800M range through 2024–2025
- Revenue exceeded emissions within approximately 2 years (self-sustaining phase)
- Among the most capital-efficient liquidity bootstrapping programs deployed to date

### Key Finding: Lock-Up is Non-Negotiable
Programs without lock-up lose **60–80% of TVL within 30 days** of incentives ending.
Lock-ups of 1–4 weeks retain 40–60% of peak TVL post-incentive.

---

## veFLOW Design

Flow's native ve(3,3) governance token mechanic:

| Component | Details |
|-----------|---------|
| Lock period | 1 week to 4 years (longer = more voting power) |
| Voting | Lock FLOW → receive veFLOW → vote for pools weekly |
| Fee distribution | 100% of trading fees from voted pools → veFLOW holders |
| Bribes | External protocols pay veFLOW holders to vote for their pools |
| Emissions | Protocol emissions directed to pools by vote weight |
| Rebase | Weekly FLOW rebase to veFLOW holders (dilution protection) |

**Protocol integration strategy:**
1. Acquire veFLOW (buy FLOW, lock for max period)
2. Vote for your protocol's pools every epoch
3. Attract third-party veFLOW votes via bribes
4. Bribe market ROI: $1 in bribes → $3–8 in emissions (Curve Wars precedent)

---

## Merkl Integration

Merkl (by Angle Protocol) is an off-chain reward distribution infrastructure usable for on-chain verified distributions.

### Setup Process
1. Deploy your incentive budget to Merkl's distributor contract
2. Configure your pool address and reward token
3. Merkl indexes LP positions, calculates rewards based on active liquidity
4. LPs claim rewards from Merkl's on-chain distributor

### Economics
| Parameter | Typical Value |
|-----------|--------------|
| Merkl fee | 3% of incentive budget |
| Break-even TVL | $200K+ (below this, direct emissions more efficient) |
| Minimum campaign | $5,000 in incentives |
| Reward calculation | Based on active liquidity (CLMM-aware) |

**Merkl advantage vs direct emissions:** Rewards only pay LPs with active liquidity (in range for CLMMs) — no wasted emissions on out-of-range positions. Typically 2–4× more capital-efficient than naive LP mining.

---

## CL Range Selection for Incentive Programs

When designing CLMM incentive ranges for a ve(3,3) or Merkl campaign:

```
Incentivize the ±20–30% range from current price for most pairs
→ Captures active LPs without incentivizing "parking" liquidity far out of range

For stablecoin pairs: ±0.5–2% (very tight, near peg)
For high-volatility pairs: ±50–100% (wider to retain LPs through volatility)
```

Range selection formula for 30-day campaigns:
```
Optimal range width = historical_30d_volatility × 1.5
(multiply by 2 for 90-day campaigns)
```

---

## Six Failure Modes

| Failure Mode | Symptom | Mitigation |
|-------------|---------|-----------|
| **Mercenary capital** | 80%+ TVL leaves when incentives end | Require lock-ups (minimum 7 days) |
| **Token price dependency** | Protocol APY drops as token price drops | Real yield component; diversify reward tokens |
| **Wrong pairs incentivized** | TVL in illiquid/unused pairs | Incentivize pairs with actual trading volume |
| **Emission rate too high** | Token inflation → death spiral | Max emission rate = 10% annual supply; reduce over time |
| **No on-chain demand** | TVL with no trading volume | Integrate aggregators before launching incentives |
| **No switching cost** | LPs exit instantly for next opportunity | Lock-up + loyalty bonuses; NFT LP positions |

---

## Protocol-Owned Liquidity (POL)

**Why POL:** Rented liquidity (incentivized LPs) leaves when incentives end. Owned liquidity stays and generates permanent fees.

**Acquisition methods:**
1. **Direct purchase:** Protocol treasury buys LP position
2. **Bond program (Olympus-style):** Users sell LP tokens to protocol at discount for vested protocol tokens
3. **Fee reinvestment:** Compound trading fees back into LP positions

**POL target:** 15–20% of total pool TVL — enough to maintain price stability if all rented LPs exit.

**Bond design:**
- Discount: 5–10% below market price (attractive but not too dilutive)
- Vesting: 5–7 day cliff (long enough to prevent arbitrage, short enough to attract participants)
- Capacity limit: Max 5% of circulating supply per epoch

---

## Pre-Incentive Volume Tactics

Launch order matters: TVL without volume is worthless; volume without liquidity is unusable.

**Week 1–2 before incentive launch:**

| Tactic | Goal |
|--------|------|
| GeckoTerminal listing | Organic discovery, volume tracking |
| DefiLlama adapter | TVL indexing (required for protocol credibility) |
| Arb bot attraction | Consistent small-volume baseline, price discovery |
| Trading competition | $5–10K prize pool generates 50–200× in volume during event |

**Trading competition design (Drift Volume Wars model):**
- 2-week duration
- Prize pool funded by protocol treasury
- Tiers: top 50 traders by volume → reduces sybil risk vs top 1000
- Minimum trade size ($100) → prevents artificial volume inflation
- Whitelist 3–5 eligible pairs → concentrates liquidity where you need it

> **See also:** `ecosystem-map.md` for current Flow DeFi landscape and missing primitive opportunities. `flow-tokenomics` skill for the governance token design that powers veFLOW-style mechanics.
