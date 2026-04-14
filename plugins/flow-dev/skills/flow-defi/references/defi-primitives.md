# DeFi Primitives on Flow

Core building blocks for DeFi protocol design. Covers lending architecture, AMM selection, and risk frameworks.

---

## Lending Protocol Design

### Health Factor Model

Standard collateralized lending uses a health factor to determine liquidation risk:

```
Health Factor = (Collateral Value × Collateral Factor) / Total Borrowed Value

Healthy:     HF > 1.2  (safe zone)
Warning:     HF 1.0–1.2 (approaching liquidation)
Liquidatable: HF < 1.0
```

**Threshold design:**

| Parameter | Conservative | Standard | Aggressive |
|-----------|-------------|----------|------------|
| Target HF | 1.5 | 1.3 | 1.15 |
| Min HF (rebalance trigger) | 1.2 | 1.1 | 1.05 |
| Liquidation HF | 1.0 | 1.0 | 1.0 |
| Collateral factor (blue-chip) | 70% | 75% | 80% |
| Collateral factor (mid-cap) | 50% | 60% | 65% |
| Collateral factor (volatile) | 30% | 40% | 50% |

### Interest Rate Kink Model

Two-slope interest rate model that accelerates rates above the optimal utilization point:

```
If utilization ≤ optimalUtilization:
  borrowRate = baseRate + (utilization / optimalUtilization) × slope1

If utilization > optimalUtilization:
  excessUtilization = utilization - optimalUtilization
  maxExcess = 1.0 - optimalUtilization
  borrowRate = baseRate + slope1 + (excessUtilization / maxExcess) × slope2
```

**Typical parameters:**

| Parameter | Conservative | Standard | Aggressive |
|-----------|-------------|----------|------------|
| Base rate | 0% | 1% | 2% |
| Optimal utilization | 80% | 85% | 90% |
| Slope 1 (below optimal) | 4% | 5% | 7% |
| Slope 2 (above optimal) | 75% | 100% | 150% |
| Max rate (100% util) | ~79% | ~106% | ~159% |

**Why kink model:** The steep slope2 above optimal utilization creates a strong economic incentive for LPs to add liquidity and for borrowers to repay — self-balancing mechanism.

### Collateral Tiers

Assign collateral factors by asset risk profile:

| Tier | Assets | Max CF | Rationale |
|------|--------|--------|-----------|
| 1 — Blue chip | FLOW, ETH, BTC | 75–80% | High liquidity, deep markets |
| 2 — Stablecoins | USDC, USDT, DAI | 85–90% | Low volatility |
| 3 — Mid-cap | Major DeFi tokens | 55–65% | Moderate liquidity |
| 4 — Volatile | Small-cap, new tokens | 30–45% | High volatility, thin markets |
| 5 — Restricted | LP tokens, exotic | 0–30% | Circular risk, manipulation risk |

### Liquidation Mechanics

```cadence
// Liquidation reward pattern
let liquidationBonus = 0.05  // 5% bonus to liquidators
let maxLiquidation = 0.5     // Max 50% of position per liquidation

// Liquidator receives: repaidDebt × (1 + liquidationBonus) in collateral
// Protocol receives: small fee (0.5–1%) from liquidation bonus
```

**Soft vs hard liquidation:** Many protocols now implement soft liquidation (partial close, rebalance) before hard liquidation (full close). This reduces bad debt but requires more complex accounting.

---

## AMM Type Selection Guide

| AMM Type | Best for | Capital efficiency | Complexity | Examples |
|----------|----------|-------------------|------------|---------|
| **xy=k (CPMM)** | Long-tail, new pairs, wide price range | Low | Low | Uniswap v2, early AMMs |
| **StableSwap** | Pegged assets (USDC/USDT, ETH/stETH) | High for peg | Medium | Curve, Balancer stable |
| **CLMM** | Established pairs, active LPs | Very high (10–100×) | High | Uniswap v3, Increment |
| **DLMM (bins)** | Volatile pairs, market making | Extreme (at current price) | Very high | Meteora, LFJ |
| **ve(3,3) / Solidly** | Governance-integrated liquidity | Medium | High | Aerodrome, Velodrome |

### Decision Framework

```
New protocol, bootstrapping liquidity
  → Start with xy=k (simpler, broader range, less active management)
  → Migrate to CLMM after establishing price discovery

Stablecoin pairs (USDC/FLOW, FLOW/stFLOW)
  → StableSwap (Curve-style) — dramatically lower slippage near peg

Established token pairs with active LPs
  → CLMM — 10–100× capital efficiency vs xy=k

Need governance + liquidity coupling
  → ve(3,3) — veFLOW votes direct emissions to your pool

Market making for new token (tight spreads)
  → DLMM — place all liquidity in current price bin
```

### CLMM Range Selection

For a token with annualized volatility `σ`:

```
Suggested range width = price × σ × √(days / 365) × 2

Example: FLOW at $1.00, 80% annual vol, 30-day LP period:
range = 1.00 × 0.80 × √(30/365) × 2 = ±0.47
→ LP range: $0.53 to $1.47
```

Tighter range = higher fee yield (more of your liquidity at price) but more frequent rebalancing.

> **Note:** This formula is a linear approximation. For large σ√(days/365) values (> 0.5), use the log-normal bounds instead: upper = price × e^(σ√(days/365)), lower = price × e^(−σ√(days/365)).

---

## Risk Framework

### Five DeFi Risk Categories

| Risk | Description | Mitigation |
|------|-------------|-----------|
| **Collateral cascade** | Price drop → liquidations → more price drop | Conservative CFs, circuit breakers, isolated markets |
| **Oracle dependency** | Price manipulation → bad debt | TWAP oracles, multiple sources, staleness checks |
| **Smart contract** | Bug in protocol code → fund loss | Audits, formal verification, timelocks, bug bounties |
| **Liquidity fragility** | Sudden LP withdrawal → high slippage, bank run | Lock-ups, withdrawal fees, gradual release |
| **Governance attack** | Flash loan voting → malicious parameter changes | Snapshot lookback, timelock, quorum requirements |

### Oracle Safety Rules

```cadence
// ❌ Never use spot price from AMM as oracle
let spotPrice = amm.getSpotPrice()  // manipulatable in same transaction

// ✅ Use TWAP (time-weighted average price)
let twapPrice = oracle.getTWAP(token: tokenAddress, period: 1800)  // 30-min TWAP

// ✅ Sanity check with deviation bounds
assert(
    twapPrice > lastKnownPrice * 0.5 && twapPrice < lastKnownPrice * 2.0,
    message: "Oracle price deviation exceeds 2× — possible manipulation"
)
```

### Circular Collateral Risk

**Problem:** Using your own protocol's LP token as collateral creates circular risk — if the protocol is under stress, collateral value and borrowed assets both collapse together.

**Rule:** Never allow LP tokens from your own protocol as Tier 1 collateral. If allowed at all, use maximum 20–30% CF with additional safeguards.

> **See also:** `liquidity-strategy.md` for bootstrapping and sustaining liquidity for your protocol. `protocol-architecture.md` for Flow-specific architectural advantages.
