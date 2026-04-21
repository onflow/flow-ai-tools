---
name: flow-orchestrate
description: |
  Multi-agent orchestrator for complex, multi-domain Flow development workflows. Spawns specialized subagents each loaded with only the references for their domain — keeps context lean and enables parallel execution.
  TRIGGER when: tasks spanning multiple domains, "build me a full dapp", "launch a DeFi protocol end-to-end", "audit and deploy my contracts", "full stack Flow app", "start a new project from scratch", "build and ship a token", "I need contracts + frontend + deployment", "set up everything".
  DO NOT TRIGGER for single-domain tasks — route directly: write one contract (cadence-scaffold), audit one file (cadence-audit), React UI only (flow-react-sdk), deploy only (flow-cli), dev environment only (flow-dev-setup), DeFi design only (flow-defi).
---

# Flow Orchestrator

Routes complex multi-domain workflows to specialized subagents. Each agent receives only the references for its domain — this keeps each agent's context 80–90% smaller than loading everything into one session.

## Why Subagents Save Tokens

Loading all 10 skills = up to ~12,000 lines of reference context in one session.
Each specialized agent loads 2–5 reference files = 500–1,500 lines per agent.
Parallel agents multiply throughput without multiplying cost per agent.

## Agent Roster

| Agent file | Domain | Skills drawn from |
|---|---|---|
| [cu-profiler.md](agents/cu-profiler.md) | Gas cost measurement | flow-cli (query-blockchain, cadence-scripts) |
| [storage-architect.md](agents/storage-architect.md) | Resource layout + CU optimization | cadence-lang (resources, anti-patterns, design-patterns) |
| [cross-vm-bridge.md](agents/cross-vm-bridge.md) | Cadence ↔ EVM boundary (COA, ABI) | flow-defi (protocol-architecture), cadence-lang (capabilities) |
| [cadence-deploy.md](agents/cadence-deploy.md) | Compile → deploy → verify cycle | flow-cli (project, commands-overview), flow-project-setup |
| [economic-designer.md](agents/economic-designer.md) | Protocol fees + treasury design | flow-tokenomics (value-accrual), flow-defi (defi-primitives) |
| [security-auditor.md](agents/security-auditor.md) | Security audit + exploit proofs | cadence-audit, cadence-lang (security, anti-patterns, entitlements) |
| [test-architect.md](agents/test-architect.md) | CDC + Go/overflow test suites | flow-dev-setup (testing), cadence-lang (resources) |

## How to Spawn an Agent

1. Open the agent template from `agents/<name>.md`
2. Read each reference file listed in the template's **Refs to embed** section
3. Build the agent prompt by combining: role description + embedded ref content + specific task
4. Call `Agent(prompt: "...")` — multiple independent agents can be called in the same turn (parallel)

```
Agent(prompt: "<role> + <embedded refs content> + <task>")
Agent(prompt: "<role> + <embedded refs content> + <task>")  ← same turn = parallel
```

## Parallel vs. Sequential

**Parallel** — agents whose inputs don't depend on each other's output:
- storage-architect + cu-profiler (design and measure simultaneously on existing code)
- security-auditor + test-architect (find bugs and write adversarial tests together)

**Sequential** — output of one feeds the next:
- storage-architect → cu-profiler → economic-designer (design → measure → price)
- security-auditor → cadence-deploy (audit must pass before deploy)
- cu-profiler → economic-designer (designer needs real numbers, never estimates)

## Navigation

| Reference | Content |
|---|---|
| [task-routing.md](references/task-routing.md) | Decision tree: task type → which agents, in which order |
| [handoff-format.md](references/handoff-format.md) | Output format each agent must produce so the next agent can consume it |
