# Handoff Format Between Agents

Every agent must end its output with a **Handoff Block** so the next agent in the chain can consume its work without re-reading everything.

## Handoff Block Structure

```markdown
---
## Handoff

**Agent:** <agent-name>
**Status:** DONE | BLOCKED | PARTIAL
**Output files:**
- path/to/file.cdc — brief description
- path/to/file.json — brief description

**For next agent (<agent-name>):**
<2–4 lines: what the next agent needs to know to start immediately>

**Open issues (if any):**
- issue 1
- issue 2
---
```

## Per-Agent Handoff Conventions

### cadence-specialist → auditor

```markdown
---
## Handoff

**Agent:** cadence-specialist
**Status:** DONE
**Output files:**
- cadence/contracts/MyNFT.cdc — NFT contract, NonFungibleToken v2, open edition
- cadence/transactions/MintNFT.cdc — public mint transaction
- cadence/scripts/GetNFT.cdc — fetch NFT metadata

**For next agent (auditor):**
Review all 3 files above. Priority: check MintNFT.cdc entitlements and
MyNFT.cdc resource storage paths. No admin gating on minting — this is
intentional (open edition). Flag if royalty handling deviates from MetadataViews spec.

**Open issues:**
- Royalty receiver address is hardcoded — should be configurable via admin resource
---
```

### cadence-specialist → infra-ops

```markdown
---
## Handoff

**Agent:** cadence-specialist
**Status:** DONE
**Output files:**
- cadence/contracts/MyNFT.cdc
- cadence/transactions/MintNFT.cdc

**For next agent (infra-ops):**
Deploy MyNFT to testnet. Contract has no constructor args — plain `flow project deploy`.
Depends on: NonFungibleToken, MetadataViews (already on testnet, add as dependencies).
Test with MintNFT.cdc after deploy to verify storage paths work.

**Open issues:** none
---
```

### auditor → cadence-specialist (fix cycle)

```markdown
---
## Handoff

**Agent:** auditor
**Status:** DONE
**Verdict:** CONDITIONAL PASS — 2 High findings must be fixed before deploy

**Findings requiring action:**
| ID | File | Line | Severity | Issue |
|----|------|------|----------|-------|
| H1 | MyNFT.cdc | 45 | High | Missing entitlement on `withdraw` — any account can drain vault |
| H2 | MintNFT.cdc | 12 | High | No pre-condition on recipient — can mint to zero address |

**For next agent (cadence-specialist):**
Fix H1 and H2 only. Do not refactor anything else — scope is minimal.
After fixes, re-run `flow test` to verify no regressions.

**Low/Medium findings (informational, no action required before deploy):**
- L1: MyNFT.cdc:78 — `description` field could be `let` instead of `var`
---
```

### auditor → infra-ops (deploy approved)

```markdown
---
## Handoff

**Agent:** auditor
**Status:** DONE
**Verdict:** PASS — cleared for testnet deploy

**For next agent (infra-ops):**
All Critical and High findings resolved. Safe to deploy to testnet.
Audited files: cadence/contracts/MyNFT.cdc (v2), cadence/transactions/MintNFT.cdc

**Open issues:** none
---
```

### defi-architect → cadence-specialist

```markdown
---
## Handoff

**Agent:** defi-architect
**Status:** DONE
**Output:** Architecture document (inline below or in docs/architecture.md)

**For next agent (cadence-specialist):**
Implement the lending contract from the architecture doc. Key constraints:
- Health factor threshold: 1.2 (liquidation at < 1.0)
- Interest rate model: kink at 80% utilization, base 2% APR, max 100% APR
- Use COA pattern for EVM composability (see architecture doc §3)
- DO NOT implement the liquidation bot — that's a separate off-chain component

**Open issues:**
- Oracle price feed address not yet decided — use placeholder for now
---
```

### infra-ops → frontend-dev

```markdown
---
## Handoff

**Agent:** infra-ops
**Status:** DONE
**Output files:**
- flow.json — configured for testnet, contract address: 0xABCD1234

**For next agent (frontend-dev):**
Contract deployed at 0xABCD1234 on testnet.
FCL config: network=testnet, accessNode=https://rest-testnet.onflow.org
Wallet: use discovery.authn.endpoint for wallet discovery.
Available transactions: MintNFT.cdc, TransferNFT.cdc
Available scripts: GetNFT.cdc, GetCollection.cdc

**Open issues:** none
---
```

## Rules for All Agents

1. **Always include the Handoff Block** — even if status is BLOCKED or PARTIAL
2. **List every output file** with its path relative to project root
3. **Be explicit about scope boundaries** — what you did NOT do (so the next agent doesn't assume)
4. **Flag open issues** even if minor — the orchestrator decides whether to address them
5. **Status meanings:**
   - `DONE` — task complete, next agent can proceed
   - `PARTIAL` — some work done, describe what's missing
   - `BLOCKED` — could not proceed, describe why (missing input, unclear requirement)
