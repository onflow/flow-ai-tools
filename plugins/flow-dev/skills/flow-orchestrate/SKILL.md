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
| [cadence-specialist.md](agents/cadence-specialist.md) | Smart contracts | cadence-lang, cadence-tokens, cadence-scaffold |
| [auditor.md](agents/auditor.md) | Security review | cadence-audit + cadence-lang security refs |
| [defi-architect.md](agents/defi-architect.md) | DeFi + tokenomics | flow-defi, flow-tokenomics |
| [infra-ops.md](agents/infra-ops.md) | Deploy + CLI | flow-cli, flow-project-setup, flow-dev-setup |
| [frontend-dev.md](agents/frontend-dev.md) | React UI | flow-react-sdk |

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

**Parallel** — agents whose inputs don't depend on another agent's output:
- cadence-specialist + defi-architect (design and contracts simultaneously)
- infra-ops + frontend-dev (deployment config and React setup simultaneously)

**Sequential** — output of one feeds the next:
- cadence-specialist → auditor (auditor needs the generated contracts)
- defi-architect → cadence-specialist (contracts implement the architecture)
- auditor → infra-ops (deploy only after audit passes)

## Navigation

| Reference | Content |
|---|---|
| [task-routing.md](references/task-routing.md) | Decision tree: task type → which agents, in which order |
| [handoff-format.md](references/handoff-format.md) | Output format each agent must produce so the next agent can consume it |
