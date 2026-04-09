# Review Output Format

## Severity Levels

### 🔴 Critical (Blocking — must fix before deployment)
Security vulnerabilities that can lead to fund loss, unauthorized access, or contract exploitation.

### 🟠 High (Fix before deployment)
Access control issues, resource handling gaps, anti-pattern violations.

### 🟡 Medium (Should fix)
Design pattern deviations, missing events, non-idiomatic code.

### 🟢 Low (Recommended)
Naming improvements, documentation, minor style issues.

---

## Single File Review Format

```
## Cadence Security Review

### Summary
[1-2 sentence overall assessment]

**Severity Counts:** 🔴 X Critical | 🟠 X High | 🟡 X Medium | 🟢 X Low

---

### 🔴 Critical Issues

#### [Issue Title]
**File/Line:** [location]
**Rule:** [which rule is violated]
**Finding:** [what is wrong]
**Risk:** [what can go wrong]
**Fix:**
```cadence
// Fixed code
```

---

### 🟠 High Issues
[same format]

### 🟡 Medium Issues
[same format]

### 🟢 Low / Recommendations
[same format]

---

### Security Verification Checklist
[Completed checklist with ✅ / ❌ per item]

### Verdict
[APPROVED / APPROVED WITH CONDITIONS / REJECTED]
[Next steps]
```

## Project-Wide Audit Format

```
## Cadence Project Security Audit

### Project Overview
[files audited, contracts/transactions/scripts count]

### Executive Summary
[overall security posture]

**Total Findings:** 🔴 X | 🟠 X | 🟡 X | 🟢 X

---

### Critical Findings (🔴)
[findings requiring immediate fix]

### High Findings (🟠)
[findings to fix before deployment]

### Medium Findings (🟡)
[findings to address]

### Low / Recommendations (🟢)
[improvements]

---

### File-by-File Summary
| File | 🔴 | 🟠 | 🟡 | 🟢 | Status |
|------|-----|-----|-----|-----|--------|

### Remediation Priority
[ordered list of what to fix first]
```

## Review Principles

1. **Evidence-based** — cite the specific rule violated and the exact line
2. **Actionable** — every finding includes a concrete fix with code
3. **Proportionate** — distinguish blocking issues from recommendations
4. **Complete** — check ALL code paths, especially error paths and edge cases
5. **Context-aware** — DeFi transactions get extra scrutiny on resource handling and capability validation

## Security Verification Checklist

### Access Control
- [ ] All fields default to `access(self)` — not `access(all)` without justification
- [ ] Privileged operations use entitlements, not `access(all)`
- [ ] No capability-typed public fields
- [ ] `access(all)` ONLY for: view functions, intentional public APIs, interface requirements

### Anti-Patterns
- [ ] No `auth(...) &Account` parameters in contract functions
- [ ] No public admin resource creation functions
- [ ] No state modification in public struct initializers
- [ ] No public fields without explicit justification

### Capabilities
- [ ] Capabilities validated before use (nil-check or `.check()`)
- [ ] Capabilities stored privately; functionality exposed through methods
- [ ] No unprotected capability publication

### Resources
- [ ] ALL code paths handle resources (move or destroy)
- [ ] Resources explicitly handled before panic calls (Cadence does NOT have `defer`)
- [ ] Move operator `<-` used consistently

### Transactions
- [ ] Entitlements minimal
- [ ] `prepare` only accesses account; business logic in `execute`
- [ ] `pre`/`post` are single boolean expressions

### NFT Contracts (if applicable)
- [ ] Implements `NonFungibleToken` interface
- [ ] Includes required MetadataViews: Display, Serial, NFTCollectionData
- [ ] One contract per `.cdc` file

### Contract Structure
- [ ] Complete `init()` — all state initialized
- [ ] Events emitted for significant state changes
- [ ] Upgrade-safe field order
