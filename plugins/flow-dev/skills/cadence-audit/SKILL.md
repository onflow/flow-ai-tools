---
name: cadence-audit
description: |
  Comprehensive audit and review skill for Cadence smart contracts on the Flow blockchain. Identifies security vulnerabilities, bugs, code quality issues, and optimization opportunities. Produces severity-rated findings (Critical/High/Medium/Low) with actionable fixes.
  TRIGGER when: auditing, reviewing, or improving Cadence code, checking for security issues, performing code review on .cdc files, looking for anti-patterns or vulnerabilities, optimizing smart contract code, "review cadence", "audit cadence", "check cadence security", "validate cadence contract", "review my .cdc file", "security review", "code review", "find vulnerabilities", "check this contract", "is this code secure", "audit my project", randomness vulnerabilities, abort-on-bad-roll, modulo bias.
  DO NOT TRIGGER when: writing new contracts from scratch (use cadence-scaffold), asking about Cadence syntax or patterns (use cadence-lang), building token contracts (use cadence-tokens).
---

# Cadence Smart Contract Audit

Conduct comprehensive security, quality, and performance reviews of Cadence smart contracts.

## Audit Modes

### Single File Review
When reviewing a specific file or code snippet, analyze it across four dimensions and produce a structured report.

### Project-Wide Audit
When auditing a full project:
1. Discover all `.cdc` files: `cadence/contracts/*.cdc`, `cadence/transactions/*.cdc`, `cadence/scripts/*.cdc`
2. If none found, search recursively from project root for `*.cdc`
3. Systematically audit each file using the checklist
4. Produce a project-level summary with file-by-file findings

## Review Dimensions

1. **Security** — Vulnerabilities, access control, resource safety, capability management
2. **Bugs** — Nil dereferences, resource loss, type confusion, infinite loops
3. **Code Quality** — Readability, naming, documentation, patterns compliance
4. **Optimization** — Unnecessary copies, storage inefficiencies, gas usage

## Quick Per-Function Checklist

- Can the field be `let` instead of `var`?
- Can the function be `view`?
- Can access be more restrictive (`access(self)`, entitled)?
- Are inputs validated with pre-conditions?
- Are results verified with post-conditions?
- Are error messages descriptive with interpolated values?

## Navigation

| Reference | Content |
|-----------|---------|
| [audit-checklist.md](references/audit-checklist.md) | Full security, bugs, quality, DeFi, optimization checklists |
| [review-format.md](references/review-format.md) | Structured output format, severity levels, verdict criteria |
| [randomness-vulns.md](references/randomness-vulns.md) | Abort-on-bad-roll, modulo bias, public Consumer cap, reveal-too-early, single-Request misuse |

## Companion Skills

- **`cadence-lang`** — Essential during audits. Consult for access control rules, entitlement patterns, resource safety, anti-patterns, and design patterns. Every audit finding should reference the specific Cadence rule being violated.
- **`cadence-tokens`** — Consult when auditing NFT/FT contracts for standard compliance (NonFungibleToken interface, MetadataViews requirements).
- **`cadence-testing`** — Use to follow up on audit findings like "missing test coverage" or "edge case not tested" with concrete test-writing guidance.
