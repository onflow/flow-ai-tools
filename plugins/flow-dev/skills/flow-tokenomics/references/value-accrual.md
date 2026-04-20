# Token Value Accrual Mechanisms

How to route protocol revenue to token holders, with real-world benchmarks and regulatory analysis.

---

## Three Mechanism Types

### 1. Real Yield — Revenue Sharing

Direct distribution of protocol fees to token stakers in non-native (non-reflexive) currency.

| Protocol | Revenue | Staker Share | Currency | Staker APY |
|----------|---------|-------------|----------|-----------|
| GMX v1 | ~$470M cumulative (v1) | 30% (v1) | ETH (v1) | 15–25% |
| Synthetix | Variable | 100% | sUSD | 5–15% |
| EtherFi | Variable | 60% | ETH | ~8% |

**Note:** GMX v2 launched August 2023 (changed fee split percentages, still ETH-denominated). In October 2024 a DAO governance vote replaced ETH/AVAX distributions with a GMX token buyback model. The table reflects v1 metrics for reference only.

**Why non-reflexive currency matters:**
- Yield in ETH/USDC = real value regardless of token price
- Yield in native token = printing; value depends on new buyers
- GMX's ETH yield survived the 2022–2023 bear market; purely-inflationary protocols didn't

**Implementation:**
```cadence
// Revenue collection pattern
access(all) contract ProtocolFees {
    access(contract) var pendingDistribution: UFix64

    // Called on each protocol interaction
    access(contract) fun collectFee(amount: UFix64) {
        let stakerShare = amount * 0.30
        let lpShare = amount - stakerShare
        self.pendingDistribution = self.pendingDistribution + stakerShare
        // route lpShare to liquidity providers
    }

    // Callable by anyone (gas incentive) — distributes accumulated fees
    access(all) fun distribute() {
        // distribute self.pendingDistribution to stakers proportionally
    }
}
```

---

### 2. Buyback & Burn

Use protocol revenue to repurchase tokens from the market and permanently destroy them.

| Protocol | Buyback Ratio | Supply model | Price performance |
|----------|--------------|-------------|-------------------|
| Hyperliquid | 97% of fees | Fixed | 5× since TGE |
| BNB | Quarterly, auto-burn formula | Capped (200M→100M) | Survived 8+ years |
| MakerDAO | $100M+ PSM surplus → buyback | Fixed | Sustained |
| Uniswap (proposed) | Fee switch vote | Fixed | Not yet activated |

**Pattern finding:** Most protocols with buyback programs still see token price decline. The exceptions (notably Hyperliquid and BNB) tend to share:
- Buyback ratio >30% of revenue
- Fixed or capped supply (burns are meaningful)
- Strong narrative (clear value prop)
- Zero or minimal VC allocation (no persistent sell pressure)

**Burn mechanics options:**

| Method | How | Best for |
|--------|-----|----------|
| Manual quarterly burns | Protocol burns accumulated tokens on schedule | Transparency, predictability |
| Auto-burn formula | Smart contract burns based on revenue formula | Trustless, continuous |
| Fee-on-transfer burn | % burned on every token transfer | High-velocity tokens only |
| Repurchase + burn | Buy from market → send to 0x0 | Tokens with deep liquidity |

---

### 3. Hybrid Mechanisms

Split revenue between multiple destinations.

**Jupiter (JUP) model:** 50% → JUP buyback (beginning Feb 2025), 50% → treasury (growth, strategy, operational stability) — not staker yield

**EtherFi model:** 60% → stakers, 40% → treasury (for protocol development)

**Common split formulas:**
```
Conservative: 20% stakers, 60% buyback, 20% treasury
Balanced:     30% stakers, 40% buyback, 30% treasury  
Growth:       40% stakers, 20% buyback, 40% treasury (reinvest in growth)
```

---

## P/E Framework

Protocol-to-earnings ratio — valuing tokens like businesses:

```
Token P/E = (Fully Diluted Valuation) / (Annualized Revenue distributed to holders)

Token FDV:  Fully diluted market cap (price × max supply)
Revenue:    Annual fees distributed to stakers/burned
```

**Example benchmarks (bull market valuations):**

| Protocol | FDV | Annual Revenue | P/E |
|----------|-----|----------------|-----|
| GMX | ~$1B (peak) | ~$100M (peak v1) | ~10× (peak) |
| AAVE | ~$5B | ~$30M | ~169× |
| CRV | ~$2B | ~$100M | ~20× |
| Hyperliquid | ~$15B | ~$200M | ~75× |

**Interpretation:** P/E < 20× suggests undervalued relative to earnings. Note: these figures are from peak bull-market periods; current protocol revenues are substantially lower. Always use current data from DefiLlama when evaluating live protocols. P/E > 100× is speculative premium. Traditional finance benchmarks: 15–25× for stable businesses.

---

## Howey Test Analysis by Mechanism

The Howey Test (from SEC v. W.J. Howey Co.) determines if an asset is a "security":
1. Investment of money
2. In a common enterprise
3. With an expectation of profit
4. Derived from the efforts of others

**Risk assessment by mechanism:**

| Mechanism | Howey risk | Reasoning |
|-----------|-----------|-----------|
| Real yield from staking | **High** | Expectation of profit from others' efforts (protocol team) |
| Buyback/burn | **Medium** | Profit from market activity; less direct than yield |
| Governance only | **Lower** | No direct profit expectation; but governance = control |
| Utility token (pay fees) | **Lower** | Consumptive use, not investment |
| DeFi primitive (liquidity) | **Varies** | Depends on passive vs active nature |

**Mitigation strategies** (consult legal counsel; this is not legal advice):
1. **Utility framing:** Token primarily used to pay for protocol services
2. **Sufficient decentralization:** Protocol operates without core team control
3. **Geographic restrictions:** Limit distribution to non-US users (Reg S)
4. **Governance gating:** Revenue distribution requires active governance vote to enable

---

## Implementation Checklist

Before deploying staking/burn contracts:

**Staking Contract Security:**
- [ ] Reentrancy protection (Cadence's resource model prevents most reentrancy)
- [ ] Reward calculation does not use manipulable spot price
- [ ] Emergency pause function controlled by multisig
- [ ] Gradual reward distribution (not instant — prevents flash loan attacks)
- [ ] Audit by two independent auditors

**Burn Contract Security:**
- [ ] Burn address is verifiably inaccessible (zero address or provably locked)
- [ ] No mechanism to reverse burns
- [ ] Supply tracking updated correctly after burns

**Vesting Contract Security:**
- [ ] Cliff enforced at contract level (not UI)
- [ ] Beneficiary change requires multisig approval
- [ ] Revocation mechanism exists for employee departures

> **See also:** `design-patterns.md` for which mechanism to choose based on your stage. `governance-compliance.md` for full regulatory analysis and DAO structure.
