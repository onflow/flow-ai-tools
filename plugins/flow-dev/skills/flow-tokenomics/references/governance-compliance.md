# Governance & Regulatory Compliance

DAO governance models, attack vectors, defenses, and regulatory considerations for token-based protocols.

---

## Governance Models

| Model | How it works | Pros | Cons | Best for |
|-------|-------------|------|------|---------|
| **Token-weighted** | 1 token = 1 vote | Simple, familiar | Whale dominance | Most DeFi DAOs |
| **Quadratic** | Vote power = √(tokens) | Reduces whale power | Sybil-vulnerable | Community DAOs with identity |
| **Conviction** | Voting weight grows over time | Reduces flash attacks | Complex UX | Grants programs |
| **Delegation** | Delegate voting to representatives | Overcomes apathy | Centralization risk | Token-weighted DAOs |
| **Futarchy** | Markets predict policy outcomes | Theoretically optimal | Extremely complex, untested at scale | **Avoid for now** |

**Practical recommendation:** Token-weighted with:
- Delegation support (overcomes the 5–10% voter turnout problem)
- 7-day timelocks on all parameter changes
- Snapshot (off-chain) for non-binding sentiment; on-chain for binding governance

---

## Attack Vectors

### 1. Flash Loan Governance Attack
Borrow massive token supply within one transaction → pass malicious proposal → repay.

**Real examples:**
- **Beanstalk ($182M, April 2022):** Attacker flash-borrowed ~$1B in LP tokens via Aave to acquire a temporary supermajority → passed an emergency governance proposal granting the attacker the entire protocol treasury → drained $182M in the same transaction
- **Build Finance ($11M, 2022):** Similar flash loan attack

**Defenses (must implement ALL of these):**
```
- Snapshot lookback: Voting power = balance 48h BEFORE proposal creation
  → Flash loans cannot affect already-counted balances
- Time lock: 7-day delay between vote passing and execution
  → Community can detect and counter-propose
- Quorum requirement: 10–20% of circulating supply must vote
  → Raises attack cost substantially
```

### 2. Governance Apathy
Reality: 5–10% of token holders vote on average. Malicious minority can reach quorum.

**Mitigations:**
- Delegation: Allow passive holders to delegate to active voters
- Voting reminders: Email/Discord notifications on new proposals
- Metagovernance: Protocols like Convex hold large delegated positions
- Low-consequence proposals first: Build voting habit with small decisions

### 3. Vote Buying (Bribes)
Legitimate at small scale (Curve Wars bribes). Becomes attack vector when:
- Malicious actor controls >10% of governance through bribes
- Bribe market prices are too low vs. treasury value

**Bribe market economics:**
- Historical bribe ROI: $1 in bribes → $3–8 in emissions directed
- Attack becomes viable when treasury value >> cost to control governance

**Defense:** Minimum governance threshold for sensitive proposals (e.g., treasury withdrawals require 25% quorum vs standard 10%)

---

## Governance Parameter Requirements

| Parameter | Minimum | Recommended |
|-----------|---------|-------------|
| Snapshot lookback | 24h | 48h |
| Voting period | 5 days | 7 days |
| Timelock delay | 48h | 7 days |
| Quorum | 5% | 10–20% |
| Proposal threshold | 0.5% | 1–5% |
| Execution delay | 24h | 48h |

---

## Proposal Structure Template

Every governance proposal should include:

1. **Title** — Clear, descriptive, no hyperbole
2. **Summary** — 2–3 sentences: what it does and why
3. **Motivation** — Problem being solved (data/evidence)
4. **Specification** — Exact technical changes with contract addresses/parameters
5. **Risk Analysis** — What could go wrong, magnitude, probability
6. **Success Metrics** — How to measure if proposal achieved its goal
7. **Timeline** — Implementation schedule with milestones
8. **Voting Options** — "Yes, execute as specified" / "No" / "Abstain"

---

## Regulatory Framework

### Howey Test (US Securities Law)

Four criteria that must ALL be met for an asset to be a security:
1. **Investment of money** — Purchaser pays money
2. **Common enterprise** — Fortunes tied to others
3. **Expectation of profit** — Buyer expects financial return
4. **From efforts of others** — Profits depend on others' work

**Application to tokens:**
- Pure utility tokens that are consumed (not held for appreciation) → lower risk
- Governance tokens with no cash flow → contested (UNI has not faced SEC action)
- Staking rewards → criterion 4 (profits from team operating protocol) → higher risk
- Fully decentralized (no controlling team) → criterion 4 fails → lower risk

### SEC Enforcement Precedents

| Case | Outcome | Lesson |
|------|---------|--------|
| Ripple (XRP) | Partial win: XRP not a security for secondary market sales | Programmatic sales ≠ investment contract |
| Telegram (TON) | $1.7B settlement, TON shutdown | Pre-launch token sales = securities |
| Coinbase (COIN) | SEC case filed 2023; status evolving — verify current state | Regulatory landscape is in flux as of 2026 |

### Four Compliance Strategies

1. **Utility framing:** Design token primarily for protocol utility (fee payment, staking). Document in whitepaper that token is not an investment.

2. **Geographic restriction:** Block US persons from TGE (Reg S compliance). US investors can only purchase on secondary market.

3. **Sufficient decentralization:** SAFT → token conversion once protocol is "sufficiently decentralized" (Ethereum precedent). Core team no longer controls protocol outcomes.

4. **Governance gating:** Revenue distribution enabled only by governance vote — team does not unilaterally promise returns.

**Recommendation:** Consult securities counsel in your jurisdiction. None of the above is legal advice.

---

## Tax Implications (US)

| Event | Tax treatment |
|-------|--------------|
| Airdrop received | Ordinary income at FMV on receipt date (Rev. Rul. 2023-14) |
| Staking rewards | Ordinary income at FMV on receipt (Rev. Rul. 2023-14) |
| Token sale | Capital gain/loss (short-term if held < 1 year) |
| NFT sale | Capital gain/loss |
| DAO governance vote | Not taxable (no economic event) |

**For founders:** Token grants/vesting → ordinary income at vesting unless Section 83(b) election filed within 30 days of grant.

---

## Global Overview

| Jurisdiction | Framework | Key requirement |
|-------------|-----------|----------------|
| **EU** | MiCA (Markets in Crypto-Assets) | In full effect since December 2024. Stablecoins (ARTs/EMTs) require issuer authorization. Utility tokens must publish a whitepaper and notify the local regulator. |
| **Singapore** | Payment Services Act (PSA) | DPT service providers require MAS license |
| **Switzerland** | FINMA categories | Payment tokens, utility tokens, asset tokens — different treatment |
| **Japan** | PSA + Financial Instruments | Crypto exchange registration required |
| **Cayman Islands** | VASP Act | Popular incorporation jurisdiction; still requires compliance in operating jurisdictions |

**MiCA (in effect December 2024):** If your token is accessible to EU users, you are already subject to MiCA. ARTs (asset-referenced tokens) and EMTs (e-money tokens) face the strictest requirements and require issuer authorization. Utility tokens: publish whitepaper, notify local regulator.

> **See also:** `launch-strategy.md` for TGE planning timeline that incorporates legal milestones. `value-accrual.md` for Howey Test analysis by specific revenue mechanism type.
