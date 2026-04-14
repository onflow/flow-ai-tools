# Token Launch Strategy

TGE playbook from planning through post-launch sustainability.

---

## Three-Phase Framework

### Phase 1: Pre-Launch (8–12 weeks before TGE)

**Week 1–4: Foundation**
- [ ] Define token utility and value accrual mechanism (see `design-patterns.md`)
- [ ] Legal review: Howey Test analysis, jurisdiction selection (see `governance-compliance.md`)
- [ ] Design Sybil resistance criteria for airdrop/points
- [ ] Deploy points program with clear, public rules
- [ ] Seed community: Discord, Twitter, initial partner announcements

**Week 5–8: Community Building**
- [ ] Points program live; track activity publicly (leaderboard)
- [ ] Launch testnet; reward genuine technical users
- [ ] Partner with 3–5 protocols for joint incentives
- [ ] Secure 2 exchange listings (at minimum: one CEX + DEX)
- [ ] Prepare DEX liquidity: $2M+ minimum for Day 1

**Week 9–12: Launch Preparation**
- [ ] Publish tokenomics publicly (distribution, vesting, mechanics)
- [ ] Complete security audit (2 auditors minimum)
- [ ] Finalize airdrop list, apply Sybil filters
- [ ] Governance framework ready (DAO structure, initial proposals)
- [ ] Market maker agreements signed

---

### Phase 2: TGE

**Ideal distribution:**

| Recipient | Allocation | Notes |
|-----------|-----------|-------|
| Community/airdrop | 40–50% | Core to credibility; Hyperliquid did 31% |
| Foundation/treasury | 20–25% | 3-year vesting, no cliff |
| Team | 15–20% | 12-month cliff + 3-year linear vest |
| Investors | 10–15% | 6-month cliff + 2-year vest |
| Advisors | 2–5% | 12-month cliff + 2-year vest |

**Day 1 requirements:**
- DEX liquidity: $2M+ (prevents whale manipulation)
- Protocol governance activated (community owns product from Day 1)
- Staking live (immediate utility, absorbs sell pressure)
- Announcement coordinated: protocol partners post simultaneously

---

### Phase 3: Post-Launch Stability (First 90 days)

- **Week 1–2:** Monitor and respond to price discovery (expected volatility)
- **Month 1:** First governance proposal live (signal active DAO)
- **Month 2:** Revenue sharing active or first buyback executed
- **Month 3:** Community transparency report (activity metrics, treasury state)

**Ongoing:**
- Quarterly burns or revenue distribution events
- Monthly community calls
- Protocol improvements via governance (not unilateral team decisions)

---

## Distribution Option Comparison

| Method | Targeting | Sybil Risk | Engagement | Examples |
|--------|-----------|-----------|-----------|---------|
| **Retroactive Airdrop** | Past users | High | Medium | Uniswap, ENS |
| **Points Program** | Active users | Medium | High | Hyperliquid |
| **Fair Launch** | Anyone | Low | High | Nouns, YFI |
| **Insider-Heavy** | VCs/team | None | Low | ICP, Aptos — **avoid** |

**Recommended: Points Program → Retroactive Allocation**
1. Define clear on-chain actions worth points (no off-chain promises)
2. Run for 8–16 weeks
3. Apply Sybil filter before snapshot
4. Convert points to token allocation proportionally with a community bonus multiplier

---

## Anti-Sybil Strategies

Layer multiple barriers:

| Barrier type | Implementation | Difficulty to game |
|-------------|----------------|-------------------|
| Wallet age | Require account created >90 days before snapshot | Medium |
| Activity threshold | 5+ on-chain transactions in protocol | Medium |
| Capital threshold | Held >$100 in protocol at any point | High |
| Social graph | Gitcoin Passport score >15 | High |
| KYC | Optional; for maximum allocation tier | Very high |

**Recommended layering:** (Wallet age 90d) AND (5+ transactions) AND (one of: $100 in protocol OR Passport score 15+)

---

## Failure Archive

| Launch | What failed | Data | Lesson |
|--------|------------|------|--------|
| **Aptos (APT)** | Botted airdrop; heavy VC allocation (51.5%) | -50% in 48h | Anti-Sybil required; insider allocation destroys trust |
| **Blast** | 100% incentive-driven TVL, no utility | -97% TVL after incentives ended | Build product before incentives |
| **Arbitrum** | Near-perfect gold standard | ~625K qualifying addresses post-Sybil filter (from 1.13M initial claims); sustained TVL | Public criteria + long points program + genuine product |
| **Hyperliquid** | Gold standard | 31% community airdrop, zero VC | Extreme community allocation + real product + buybacks |
| **Drift Volume Wars** | Competition design model | Volume spikes during event, baseline increase after | Competitions with floor ($100 min) and tiers work |

---

## Market Psychology: 2026 Context

**Current narrative landscape:**
1. **Real yield** — Market rewards protocols with actual revenue. "Inflationary rewards" is a red flag.
2. **Deflationary supply** — Buyback/burn mechanics command premium valuation.
3. **Community ownership** — Low insider allocation (≤25%) seen as credibility signal.
4. **Transparency** — On-chain verifiable everything. Off-chain promises = discounted.

**Four-phase crypto cycle:**
```
Accumulation → Bull (retail) → Distribution → Bear → Accumulation
```

**2026 positioning:** Protocols launching in early bull or accumulation phase have best narrative leverage. Launches in late-bull face immediate sell pressure as early holders distribute.

**Timing TGE:**
- Launch when your protocol has 3+ months of activity data (credibility)
- Do NOT launch at peak hype without product (Blast mistake)
- Fear of missing bull market → rushed launch → failed TGE → worse than waiting

> **See also:** `governance-compliance.md` for legal structure decisions that should be made before TGE. `value-accrual.md` for the post-launch revenue mechanism that drives long-term token health.
