# Token Design Patterns

Proven patterns with real-world metrics, and anti-patterns with failure analyses.

---

## Five Proven Patterns

### 1. Real Yield (Recommended Default)
Distribute actual protocol revenue (not token inflation) to stakers.

**Case study: GMX v1**
- ~$470M cumulative fees generated (v1 era); 30% → GMX stakers in ETH, 70% → GLP LPs
- Sustained 15–25% ETH APY during high-activity periods; token survived bear markets because cash flows were real
- **Note:** GMX v2 (launched October 2024) restructured the fee model — staker ETH distribution was replaced with a buyback mechanism. Verify current GMX v2 mechanics if using as a reference

**Case study: Synthetix**
- Revenue from synth trading fees → SNX stakers
- Stakers must maintain C-ratio (collateralization) — aligns incentives

**When to use:** Protocol with genuine revenue ($1M+ annualized). Real yield loses credibility below this threshold.

---

### 2. Buyback & Burn
Use protocol revenue to repurchase and burn circulating supply.

**Case study: Hyperliquid (HYPE)**
- 97% of trading fees → buyback
- 5× price appreciation since TGE
- Fixed supply, so burns create genuine deflation
- Community-owned: 31% airdrop, no VC allocation

**Case study: BNB**
- Quarterly burns based on revenue
- Auto-burn mechanism: transparent formula
- Still operating after 7+ years

**When to use:** Early-stage protocol with revenue but not enough to meaningfully yield individual stakers. Burns compound over time.

**Critical finding:** 7 of 9 tokens with buyback programs decline anyway. Exceptions share: >30% buyback ratio, fixed supply, strong narrative, zero/minimal VC allocation.

---

### 3. veToken (Governance Coupling)
Lock tokens to receive voting power that directs protocol emissions.

**Case study: Curve (CRV/veCRV)**
- Lock CRV for up to 4 years → veCRV
- 40–50% of total supply locked
- Voting power directs gauge weights (emissions to pools)
- Created the "Curve Wars" — protocols pay billions in bribes to veCRV holders
- Convex Finance built a $3B protocol on top of this primitive

**Mechanics:**
```
Lock 1 CRV for 4 years → 1 veCRV
Lock 1 CRV for 1 year → 0.25 veCRV
veCRV decays linearly to 0 → incentive to re-lock
```

**When to use:** Protocols that need to direct liquidity (DEXes, lending markets). Creates sustainable incentive flywheel.

---

### 4. Dual-Token
Separate governance/staking token from yield-bearing/stable token.

**Case study: MKR/DAI**
- DAI: stability mechanism (soft-peg to $1)
- MKR: governance token (burned when surplus, minted when undercollateralized)
- MKR holders absorb tail risk in exchange for fees

**Case study: GMX/GLP**
- GMX: governance + fee-sharing staking token
- GLP: LP index token (holds basket of assets; earns 70% of fees)
- Different risk profiles attract different investors

**When to use:** Protocol needs both a stable medium of exchange AND a governance/value-capture token.

---

### 5. NFT + Token Hybrid
NFTs as governance assets with token utility.

**Case study: Nouns DAO**
- 1 Noun auctioned daily forever (no max supply)
- Noun holders vote on treasury ($40M+) allocations
- Revenue from auctions → treasury → community grants
- No pre-mine, no VC allocation

**When to use:** Community-first protocols, creative/cultural projects, DAOs prioritizing long-term governance over token speculation.

---

## Five Anti-Patterns

### 1. Pure Governance (No Cash Flow)
Governance rights alone don't drive token value.

**Case study: UNI (Uniswap)**
- $1T+ in trading volume generated
- 0% of fees → UNI holders (all fees to LPs)
- UNI holder receives no cash flow, only theoretical governance rights
- Token price driven entirely by speculation, not fundamentals

**Lesson:** Governance without fee switch is marketing, not value accrual.

---

### 2. Excessive Emissions
High emissions collapse token price, destroying the APY they're supposed to offer.

**Case study: Olympus (OHM)**
- Peak APY: 8,000%+ 
- Required constant new buyers to maintain price
- Death spiral: price fell → APY in dollar terms fell → fewer buyers → more price pressure
- Peak: $1,400 → Trough: $10 (-99%)

**Rule:** Max annual emission rate = 10% of circulating supply. Reduce over time.

---

### 3. Algorithmic Stables Without Backing
Stablecoins backed only by their paired governance token cannot survive bank runs.

**Case study: TerraLUNA**
- UST maintained peg via LUNA mint/burn
- During panic: UST → sell LUNA → LUNA price falls → UST peg breaks → more LUNA minted → hyperinflation
- $40 billion in value destroyed in 72 hours

**Rule:** Stablecoins require $1+ in collateral per $1 in circulation. Algorithmic mechanisms can optimize, not replace, collateral.

---

### 4. Ponzi Yield
Unsustainably high yields funded by new deposits, not protocol revenue.

**Case study: Anchor Protocol**
- 20% APY on UST "guaranteed" by Terraform Labs
- Subsidized from TFL treasury, not real yield
- Attracted $18B in deposits
- Collapsed when TFL could no longer sustain subsidies

**Rule:** If you can't explain where the yield comes from, it's a Ponzi.

---

### 5. Heavy Insider Allocation
Large VC/founder allocations create persistent sell pressure.

**Case studies:**
- Aptos (APT): 51.5% to insiders → botted airdrop, -50% in 48h
- ICP (Internet Computer): 40%+ to insiders → -95% from peak

**Best practice:**
```
Community/public: 40–50%
Foundation/treasury: 20–25%
Team (vested): 15–20%
Investors (vested): 10–15%
Advisors: 2–5%
```

---

## Supply Design Options

| Model | Example | Best for | Risk |
|-------|---------|----------|------|
| **Fixed supply** | Bitcoin (21M) | Strong store-of-value narrative | No flexibility for incentives |
| **Capped + burns** | BNB (200M→100M) | DeFi protocols with revenue | Requires sustained burns |
| **Uncapped + sinks** | ETH, CRV | Protocols needing ongoing emissions | Inflation if sinks fail |
| **Elastic** | Ampleforth | Stable unit of account | Complex, confusing UX |

**Recommended default for new Flow protocols:** Capped supply with transparent burn mechanism tied to protocol revenue.

---

## Context Decision Matrix

| Stage | Revenue | Community | Recommended pattern |
|-------|---------|-----------|-------------------|
| Pre-launch | None | Small | Points program → retroactive airdrop |
| Early ($0–500K ARR) | Low | Growing | veToken + small emissions |
| Growth ($500K–5M ARR) | Moderate | Established | Real yield + buybacks |
| Mature ($5M+ ARR) | High | Large | Real yield + governance |

> **See also:** `value-accrual.md` for implementation details of each revenue mechanism. `launch-strategy.md` for TGE execution.
