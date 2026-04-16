# Flow DeFi Ecosystem Map

Current state of DeFi on Flow, missing primitives, and opportunity analysis.

---

## Current State (Q1 2026)

| Metric | Value |
|--------|-------|
| DEX TVL | ~$30–50M |
| Daily DEX volume | ~$2–5M |
| DEX/CEX volume ratio | ~15% (improving) |
| Lending TVL | ~$10–20M |
| Active DeFi protocols | ~8–12 |

---

## Existing Primitives

### DEXes

| Protocol | AMM Type | Notes |
|----------|----------|-------|
| IncrementFi | CPAMM + Stableswap | Largest DEX by TVL; Flow's primary AMM (volatile pairs: xy=k constant product; stable pairs: Solidly stableswap curve) |
| KittyPunch | EVM-based | Full-suite DEX (PunchSwap AMM, StableKitty stableswap, AggroKitty aggregator) with KUSD stablecoin and yield vaults on Flow EVM |

### Bridges

| Bridge | Architecture | Use case |
|--------|-------------|----------|
| Wormhole | Lock/mint | CEX canonical bridge; high security guarantees |
| deBridge | Cross-chain message | User-facing bridge; faster UX |

**Bridge selection guide:**
- Wormhole for CEX integrations and high-value transfers (proven security)
- deBridge for user-facing UI where speed matters
- Native Crescendo bridge for EVM↔Cadence within Flow (no bridge needed)

### Lending

Early-stage lending markets exist on Flow; sector is underdeveloped vs lending volume on comparable chains.

---

## Missing Primitives (Opportunity Map)

### 1. Perp DEX

**Opportunity:** No established perpetual futures exchange on Flow.

**Prerequisites before building:**
- $30–50M DEX spot TVL (needed for perp funding rate arbitrage)
- Reliable oracle infrastructure for mark prices
- 6–12 months of DEX price history for funding rate credibility

**Flow advantage:** MEV-free execution → no front-running of liquidations, no sandwich attacks on margin calls. On Ethereum perp DEXes, liquidators extract significant value from position closes.

**Current status:** Prerequisites not yet met. Build in 2026–2027 horizon.

### 2. Prediction Markets

**Opportunity:** Sports prediction market on Flow with direct wallet integration.

**Flow advantage:** Sports-engaged user base (NBA Top Shot, NFL All Day, UFC Strike) — organic alignment for sports prediction markets. Flow has approximately 1M MAU (Flow Foundation, early 2026). Native VRF for provably fair resolution. MEV-free for fair price discovery.

**Architecture:** Cadence contract for position management + EVM for liquidity pools (cross-VM atomic) + RandomBeaconHistory for randomness.

**Current status:** Immediate opportunity. Low competition, strong user-fit.

### 3. Launchpad

**Opportunity:** Token launch platform leveraging Flow's MEV-free environment.

**MEV-free advantage for launches:**
- Bonding curve purchases are front-run on every other chain
- On Flow: all buyers get fair access at the same step of the curve
- No sniping bots drain the first buyers

**Bonding curve mechanics:**
```
Price = initialPrice × (1 + k)^tokensSold
where k = graduation parameter (typically 0.00001–0.0001)
(Note: This is a discrete exponential approximation. Pump.fun itself uses
constant-product AMM mechanics with virtual reserves, not this formula directly.)

Graduation threshold: typically 10–20% of supply sold
→ Protocol receives initial bonding curve liquidity
→ Migrates to DEX at graduation with POL from curve proceeds
```

**Graduation threshold design:**
- Pump.fun model: 80% sold on bonding curve, 20% to DEX LP
- Conservative: 50% sold on curve → more DEX liquidity at graduation

### 4. Yield Aggregator

Compound positions across Flow DeFi protocols automatically. Low complexity, high TVL leverage.

---

## Competitor Pull Factors and Flow Counter-Narrative

Understanding why developers choose other chains — and how to position against them:

| Chain | Why developers choose it | Flow counter-narrative |
|-------|--------------------------|----------------------|
| Solana | Speed, low fees, large DeFi ecosystem | Flow has better sports/gaming users + MEV-free |
| Base | Coinbase distribution, EVM compatibility | Flow supports EVM AND Cadence; better for novel DeFi |
| Sui | Object model similar to Flow | Flow has established sports/gaming user base, more liquidity |

**Flow's strongest positioning:**
1. Sports/gaming-engaged users that other chains don't have
2. MEV-free environment (structural advantage for LPs and users)
3. Cross-VM atomic composability (unique vs all competitors)
4. Native account abstraction (wallets are first-class, no plugins needed)

---

## DefiLlama Adapter

Required for protocol credibility — without a DefiLlama listing, most DeFi users won't consider the protocol serious.

**Integration steps:**
1. Fork `DefiLlama/DefiLlama-Adapters`
2. Create `projects/<your-protocol>/index.js`
3. Implement `tvl()` function querying your contracts
4. Submit PR (typically 1–2 week review)

Minimum viable adapter:
```javascript
const { fetchURL } = require("../helper/utils");

module.exports = {
  flow: {
    tvl: async () => {
      // Query your contracts or an API endpoint for TVL data
      // See existing Flow adapters in the DefiLlama-Adapters repo for examples
      const data = await fetchURL(/* your API endpoint */);
      return { flow: data.tvl };
    }
  }
};
```

> **See also:** `liquidity-strategy.md` for bootstrapping approach once you have product-market fit. `defi-primitives.md` for technical architecture of each primitive type.
