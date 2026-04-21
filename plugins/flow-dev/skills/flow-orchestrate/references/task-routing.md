# Task Routing — Decision Tree

Maps task keywords to the right agent combination, order, and parallelism.

## Step 1 — Identify the task type

| Task type | Keywords |
|---|---|
| CU / gas measurement | "CU", "gas cost", "9999", "batch size", "MAX_SAFE_N", "how expensive" |
| Storage / layout optimization | "CU too high", "optimize storage", "dict vs array", "borrow in loop", "resource layout" |
| EVM / cross-chain | "EVM", "COA", "coa.call", "dryCall", "ABI", "Solidity", "cross-VM" |
| Deploy / compile | "deploy", "testnet", "mainnet", "compile error", "flow.json", "update contract" |
| Fee / economic model | "fee", "INDEX_FEE", "treasury", "royalty cut", "loyalty points", "profit split", "solvency" |
| Security audit | "audit", "vulnerabilities", "review", "exploit", "secure", "before mainnet" |
| Tests | "test", "coverage", "adversarial", "prove the fix", "flow test", "Go/overflow" |

If only **1 type** → spawn that single agent directly, no orchestration needed.
If **2+ types** → proceed to Step 2.

## Phase 0 — Project dependencies (always run first)

Before spawning any agent that reads or writes `.cdc` files, YOU (the orchestrator)
must ensure standard contracts are available in the project. Do not ask the user to
do this — run it yourself:

```bash
# Check what dependencies are already declared
cat flow.json | grep -A5 '"dependencies"'

# Install missing standard contracts into the project
flow dependencies install
```

If `flow.json` has no `dependencies` section yet, add the required ones first using
`flow config add dependency` or by editing `flow.json` directly per the addresses in
`flow-project-setup/references/configuration.md`, then run `flow dependencies install`.

This resolves NonFungibleToken, FungibleToken, MetadataViews, etc. into the project
so agents never need to search the filesystem for them.

## Step 2 — Select workflow

### New contract from scratch
```
cadence-deploy (setup flow.json + emulator)
```

### New contract + audit before deploy
```
security-auditor + test-architect   [parallel — find bugs and write tests simultaneously]
  ↓ if CONDITIONAL PASS
cadence-deploy
```

### Optimize an existing transaction hitting CU limits
```
storage-architect + cu-profiler     [parallel on existing code]
  ↓
cu-profiler (re-measure after changes)
  ↓
economic-designer (recalculate fees)
```

### DeFi protocol: design → contracts → ship
```
Turn 1: [no orchestrator needed — use flow-defi skill directly for architecture]

Turn 2 (after architecture is defined):
  security-auditor + test-architect   [parallel]
    ↓ PASS
  cu-profiler
    ↓
  economic-designer
    ↓
  cadence-deploy
```

### Protocol with EVM composability
```
cross-vm-bridge                        [Cadence ↔ EVM layer]
  ↓
security-auditor                       [audit including COA patterns]
  ↓
cadence-deploy
```

### Full audit + fix cycle
```
security-auditor + test-architect      [parallel]
  ↓ CONDITIONAL PASS (findings exist)
[cadence-specialist or direct editing for fixes]
  ↓
security-auditor (re-audit changed files only)
  ↓
test-architect (re-run adversarial tests)
  ↓ PASS
cadence-deploy
```

### Token launch (economics + contracts + deploy)
```
economic-designer (fee model + treasury design)
  ↓
security-auditor + test-architect      [parallel]
  ↓ PASS
cu-profiler (measure mint/transfer transactions)
  ↓
economic-designer (validate fees against real CU)
  ↓
cadence-deploy
```

## Step 3 — Scope each agent precisely

Vague tasks produce bad output. Before spawning, reduce each agent's task to one sentence:

| Agent | Good scope example |
|---|---|
| cu-profiler | "Measure BatchMint.cdc at N=[64,128,256,512] on testnet. Find MAX_SAFE_N." |
| storage-architect | "Review cadence/contracts/Registry.cdc. Transaction costs 4,200 CU at N=256. Find the top 2 cuts." |
| cross-vm-bridge | "Implement Cadence wrapper for EVM staking pool at 0x1234. Function: stake(uint256). Read balance after." |
| cadence-deploy | "Deploy MyNFT.cdc to testnet. No constructor args. Run post-deploy verification script." |
| economic-designer | "Given MAX_SAFE_N=512, FEE_PER_TX=0.00089 FLOW, calculate INDEX_FEE and solvency at $0.50 FLOW." |
| security-auditor | "Audit cadence/contracts/MyNFT.cdc and cadence/transactions/MintNFT.cdc. Produce findings with severity." |
| test-architect | "Write test suite for MyNFT.cdc. Auditor found H1 (loyalty farming) and H2 (unauthorized withdraw). Prove both blocked." |

## Step 4 — Check file conflicts before parallel spawn

Agents running in parallel must not write to the same files:

| Pair | Safe? | Note |
|---|---|---|
| security-auditor + test-architect | ✅ | auditor produces report; test-architect writes test files |
| storage-architect + cu-profiler | ✅ | architect edits .cdc; profiler only runs CLI commands |
| cadence-deploy + any writer | ❌ | deploy reads files — writers must finish first |
| economic-designer + cu-profiler | ❌ | designer needs profiler output |
