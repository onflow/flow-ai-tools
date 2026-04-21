# Task Routing — Decision Tree

Use this to determine which agents to spawn and in which order.

## Step 1 — Identify Domains in the Task

Count how many of these domains the task touches:

| # | Domain | Signals |
|---|---|---|
| A | Smart contracts | "contract", "cadence", ".cdc", "NFT", "FT", "vault", "resource" |
| B | Security audit | "audit", "review", "vulnerabilities", "secure", "check my contracts" |
| C | DeFi / Tokenomics | "DeFi", "AMM", "lending", "tokenomics", "TGE", "veFLOW", "yield" |
| D | Deploy / CLI / Setup | "deploy", "testnet", "mainnet", "flow.json", "CLI", "emulator", "environment" |
| E | React frontend | "React", "frontend", "UI", "hooks", "wallet connect", "dapp" |

If only **1 domain** → do NOT use the orchestrator. Route directly to the skill for that domain.
If **2+ domains** → proceed to Step 2.

## Step 2 — Select Agents

| Task pattern | Agents | Order |
|---|---|---|
| New project from scratch | cadence-specialist, infra-ops | parallel |
| New project + frontend | cadence-specialist, infra-ops, frontend-dev | cadence-specialist ∥ infra-ops, then frontend-dev |
| Full dapp (contracts + frontend + deploy) | cadence-specialist, auditor, infra-ops, frontend-dev | cadence-specialist → auditor → infra-ops ∥ frontend-dev |
| DeFi protocol (design + contracts) | defi-architect, cadence-specialist | defi-architect → cadence-specialist |
| DeFi protocol full launch | defi-architect, cadence-specialist, auditor, infra-ops | defi-architect → cadence-specialist → auditor → infra-ops |
| Token launch (tokenomics + contracts) | defi-architect, cadence-specialist | defi-architect → cadence-specialist |
| Audit + fix + redeploy | auditor, cadence-specialist, infra-ops | auditor → cadence-specialist → infra-ops |
| Existing project: add feature + audit | cadence-specialist, auditor | cadence-specialist → auditor |
| Setup + scaffold + deploy | infra-ops, cadence-specialist | infra-ops ∥ cadence-specialist, then infra-ops (deploy phase) |

## Step 3 — Refine Each Agent Scope

Before spawning, clarify the exact sub-task for each agent. Agents work best with narrow, concrete instructions:

**Too broad:** "build the contracts"
**Good:** "Write a Cadence NFT contract implementing NonFungibleToken v2 with MetadataViews.Display and royalties. No admin minting — public open edition. Output to cadence/contracts/MyNFT.cdc"

**Too broad:** "set up the project"
**Good:** "Initialize flow.json for testnet. Configure the MyNFT contract deployment. Provide the exact `flow project deploy` command. Do NOT write any Cadence code."

## Step 4 — Check for File Conflicts

Agents running in parallel must not write to the same files.

| Agent pair | Safe to parallelize? | Notes |
|---|---|---|
| cadence-specialist + defi-architect | ✅ Yes | defi-architect produces a doc; cadence-specialist writes .cdc files |
| cadence-specialist + frontend-dev | ⚠️ Usually yes | Ensure they target different directories (cadence/ vs. src/) |
| cadence-specialist + infra-ops | ⚠️ Conditionally | infra-ops touches flow.json; cadence-specialist writes .cdc files — different files, safe |
| cadence-specialist + auditor | ❌ No | Auditor needs contracts to already exist |
| auditor + infra-ops | ❌ No | Deploy only after audit approves |

## Common Workflows

### New full-stack Flow dapp
```
Turn 1 (parallel):
  Agent(cadence-specialist) → writes contracts to cadence/
  Agent(infra-ops)          → writes flow.json, deployment config

Turn 2 (sequential):
  Agent(auditor)            → reviews cadence/ output from Turn 1

Turn 3 (parallel):
  Agent(infra-ops)          → runs deployment (uses audit-approved contracts)
  Agent(frontend-dev)       → scaffolds React app with @onflow/react-sdk
```

### DeFi protocol from idea to deployed
```
Turn 1:
  Agent(defi-architect)     → produces architecture doc + token model

Turn 2 (parallel):
  Agent(cadence-specialist) → implements contracts from architecture doc
  Agent(infra-ops)          → sets up flow.json, emulator config

Turn 3:
  Agent(auditor)            → reviews all contracts

Turn 4:
  Agent(infra-ops)          → deploys to testnet
```

### Audit + fix cycle
```
Turn 1:
  Agent(auditor)            → produces findings with severity ratings

Turn 2:
  Agent(cadence-specialist) → applies fixes for Critical/High findings

Turn 3:
  Agent(auditor)            → re-audits changed files only
```
