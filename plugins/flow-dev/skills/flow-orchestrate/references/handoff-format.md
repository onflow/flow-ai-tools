# Handoff Format Between Agents

Every agent ends its output with a **Handoff Block**. The next agent reads only this block to know what was done and what it needs to do — it does not re-read the full output.

## Handoff Block Structure

```
---
## Handoff
**Agent:** <agent-name>
**Status:** DONE | PARTIAL | BLOCKED
**Output files:**
- <path> — <one-line description>
**For next agent (<name>):**
<2–4 lines: exactly what the next agent needs to start immediately>
**Open issues (if any):**
- <issue>
---
```

**Status meanings:**
- `DONE` — task complete, next agent can proceed
- `PARTIAL` — some work done; describe what's missing
- `BLOCKED` — could not proceed; describe why

## Agent-specific handoff examples

### cu-profiler → economic-designer
```
---
## Handoff
**Agent:** cu-profiler
**Status:** DONE
**MAX_SAFE_N:** 512
**FEE_PER_TX:** 0.00089 FLOW
**FEE_PER_ENTRY:** 0.00000174 FLOW
**For next agent (economic-designer):**
Use MAX_SAFE_N=512 and FEE_PER_ENTRY=0.00000174 FLOW as inputs.
Do not re-measure — use these numbers directly.
Current FLOW price: $0.72
**Open issues:**
- At N=768 the tx sometimes hits 9,100 CU — treat 512 as safe ceiling
---
```

### storage-architect → cu-profiler
```
---
## Handoff
**Agent:** storage-architect
**Status:** DONE
**Output files:**
- cadence/contracts/Registry.cdc — converted artist registry from [UInt64] to {UInt64: Bool}, borrow moved outside loop
**CU savings estimate:** ~3,200 CU/tx at N=256 (from dict→array and borrow-outside-loop)
**For next agent (cu-profiler):**
Measure Registry.cdc at same sweep as baseline (N=[64,128,256,512]).
Compare FEE_PER_ENTRY before/after to confirm savings.
**Open issues:** none
---
```

### security-auditor → cadence-specialist (fix cycle)
```
---
## Handoff
**Agent:** security-auditor
**Status:** DONE
**Verdict:** CONDITIONAL PASS — fix H1 and H2 before deploy

**Findings requiring action:**
| ID | File | Lines | Severity | Issue |
|----|------|-------|----------|-------|
| H1 | MyNFT.cdc | 45 | 🟡 High | Missing entitlement on withdraw — any account can drain vault |
| H2 | MintNFT.cdc | 12 | 🟡 High | No pre-condition on recipient — can mint to zero address |

**For next agent (cadence-specialist or direct edit):**
Fix H1 and H2 only. Minimal scope — do not refactor anything else.
After fixes, re-run `flow test` to verify no regressions.

**Low findings (no action required before deploy):**
- L1: MyNFT.cdc:78 — description field could be let instead of var
---
```

### security-auditor → cadence-deploy (cleared)
```
---
## Handoff
**Agent:** security-auditor
**Status:** DONE
**Verdict:** PASS — cleared for testnet deploy
**Audited files:** cadence/contracts/MyNFT.cdc, cadence/transactions/MintNFT.cdc
**For next agent (cadence-deploy):**
All Critical and High findings resolved. Safe to deploy to testnet.
No constructor args. Run post-deploy verification script after deploy.
**Open issues:** none
---
```

### test-architect → security-auditor (re-audit trigger)
```
---
## Handoff
**Agent:** test-architect
**Status:** DONE
**Tests:** 12 total — 7 positive, 5 adversarial
**Results:** ✅ 11 passed / ❌ 1 failed

EXPLOIT TESTED: H1 (loyalty farming)
EXPECTED: points ≤ 10.0 after deposit-withdraw cycle
RESULT: ❌ EXPLOITABLE — points reached 340.0

**For next agent (security-auditor):**
H1 is still exploitable. Test output above confirms the attack vector.
Re-audit cadence/contracts/Registry.cdc lines 88–102 specifically.
**Open issues:** none
---
```

### test-architect → cadence-deploy (all clear)
```
---
## Handoff
**Agent:** test-architect
**Status:** DONE
**Tests:** 12 total — 7 positive, 5 adversarial
**Results:** ✅ 12 passed
**Exploits verified blocked:** H1 (loyalty farming), H2 (unauthorized withdraw)
**Coverage:** 87% — uncovered: Treasury.emergencyWithdraw (requires multisig setup)
**For next agent (cadence-deploy):**
All adversarial tests pass. Safe to deploy.
Known gap: emergencyWithdraw not covered — requires Go/overflow test with multisig (future).
**Open issues:** none
---
```

### cadence-deploy → any consumer
```
---
## Handoff
**Agent:** cadence-deploy
**Status:** DONE
**Deployed contracts:**
- MyNFT at 0xABCD1234 on testnet
**Post-deploy check:** ✅ read script returned initialized collection, write tx sealed
**For next agent (frontend or economic-designer):**
Contract live at 0xABCD1234 on testnet.
FCL: network=testnet, accessNode=https://rest-testnet.onflow.org
Available transactions: MintNFT.cdc, TransferNFT.cdc
Available scripts: GetNFT.cdc, GetCollection.cdc
**Open issues:** none
---
```

## Rules for all agents

1. Always include the Handoff Block — even if BLOCKED
2. List every output file with path relative to project root
3. Be explicit about scope boundaries — what you did NOT do
4. Status `DONE` means the next agent can proceed without asking questions
5. If BLOCKED, describe the exact input that was missing so the orchestrator can fix it
