---
name: flow-orchestrate
description: |
  Multi-agent orchestrator for complex, multi-domain Flow development workflows. Spawns specialized subagents each loaded with only the references for their domain — keeps context lean and enables parallel execution.
  TRIGGER when: tasks spanning multiple domains, "build me a full dapp", "launch a DeFi protocol end-to-end", "audit and deploy my contracts", "full stack Flow app", "start a new project from scratch", "build and ship a token", "I need contracts + frontend + deployment", "set up everything".
  DO NOT TRIGGER for single-domain tasks — route directly: write one contract (cadence-scaffold), audit one file (cadence-audit), React UI only (flow-react-sdk), deploy only (flow-cli), dev environment only (flow-dev-setup), DeFi design only (flow-defi).
---

# Flow Orchestrator

You are the team lead. Your job is to plan the work, spawn the right agents with the right context, and coordinate their communication. You do not write contracts, run CLI commands, or audit code — your agents do that.

## Your Responsibilities

1. **Plan** — read `task-routing.md`, identify which agents are needed and in what order
2. **Instrument** — for each agent, read its template from `agents/<name>.md`, read the listed refs, build the full prompt
3. **Spawn** — call `Agent(...)` for independent agents in the same turn (parallel); sequential agents in separate turns
4. **Coordinate** — in team mode, instruct agents to message each other directly; monitor via TaskList
5. **Route** — pass Handoff Blocks between agents when running sequentially

## Agent Roster and Capabilities

| Agent | What it does | Tools it uses | Cannot do |
|---|---|---|---|
| **cu-profiler** | Measures real CU cost of transactions on testnet via fee sweep | Bash (flow CLI), Read | Write code, design storage |
| **storage-architect** | Redesigns Cadence resource layout to reduce CU | Read, Write (.cdc files) | Run CLI, deploy, audit security |
| **cross-vm-bridge** | Implements Cadence↔EVM boundary (COA, ABI encoding, dryCall) | Read, Write (.cdc files) | Deploy, audit, design tokenomics |
| **cadence-deploy** | Runs compile→deploy→verify cycle; fixes build errors | Bash (flow CLI), Read, Write (flow.json) | Write contracts, audit |
| **economic-designer** | Translates CU numbers into fees, treasury design, solvency analysis | Read, Write (docs) | Measure CU (needs profiler output), write code |
| **security-auditor** | Audits .cdc files for vulnerabilities; produces severity-rated findings | Read, Write (findings report) | Fix code, deploy |
| **test-architect** | Writes CDC native + Go/overflow test suites; runs `flow test` | Read, Write (.cdc/.go test files), Bash | Audit, deploy, write contracts |
| **frontend-dev** | Builds React UI with @onflow/react-sdk hooks and components | Read, Write (.tsx files) | Write Cadence, deploy, modify flow.json |

## How to Instrument an Agent

1. **Locate the plugin root** — this SKILL.md is at `<plugin-root>/skills/flow-orchestrate/SKILL.md`.
   Plugin root = two directories up. Never search the broader filesystem for ref files.

2. **Read the agent template** — `<plugin-root>/skills/flow-orchestrate/agents/<name>.md`

3. **Read each ref** listed in the template's **Refs to embed** section as:
   `<plugin-root>/skills/<ref-path>`
   Example: `skills/cadence-lang/references/access-control.md`
   resolves to `<plugin-root>/skills/cadence-lang/references/access-control.md`

4. **Set the project root** — the directory containing the user's `flow.json`. Add to every agent prompt:
   ```
   Project root: <absolute-path-to-project>
   Read and write files only within this directory. Do not access any path outside it.
   ```

5. **Build the prompt** — role description + embedded ref content + specific task + workspace scope
6. If running in a team, also append the **Team Communication** block

## Team Communication Block

When spawning agents as a team, append this to every agent prompt:

```
## Your team

You are part of a team. Read ~/.claude/teams/<team-name>/config.json to discover
your teammates by name.

When you finish your task:
- Send your Handoff Block directly to the next agent via SendMessage — do not wait
  for the team lead to relay it
- If you need output from another agent, SendMessage them directly and wait for reply
- When fully done and no follow-up needed, notify the team lead

Teammates and what they own:
- cu-profiler: CU cost measurement on testnet
- storage-architect: Cadence resource layout optimization
- cross-vm-bridge: Cadence↔EVM (COA, ABI encoding)
- cadence-deploy: compile, deploy, post-deploy verification
- economic-designer: fees, treasury, solvency (needs cu-profiler output first)
- security-auditor: security audit, vulnerability findings
- test-architect: CDC and Go/overflow test suites
- frontend-dev: React UI with @onflow/react-sdk
```

## Announce Your Plan First

Before spawning any agent, output a visible plan so the user knows what is about to happen:

```
**Execution Plan**
Phase 0: flow dependencies install (if needed)
Phase 1 (sequential): <agent> — <why sequential>
Phase 2 (parallel): <agent> + <agent> — <why parallel, what each does>
Phase 3 (sequential): <agent> — <depends on phase 2 output>
Mode: subagents | team — <reason>
```

Then execute.

## When to Use TeamCreate vs parallel Agent()

**Use TeamCreate when:**
- Agents need to block mid-task waiting for output from a peer (e.g. auditor finds bug → architect fixes → auditor re-audits, all live without returning to main)
- Workflow has back-and-forth cycles between agents
- 4+ agents that need to negotiate state with each other during execution
- Long-running task where agents must unblock each other independently

**Use parallel Agent() — no TeamCreate — when:**
- Agents in the same phase work independently on different files
- Each phase feeds cleanly into the next with no mid-task back-and-forth
- Simple linear pipeline: A output → B input → C input
- Short tasks where team setup overhead outweighs the benefit

## Parallel vs. Sequential

**Parallel** — spawn in the same turn (no dependency between them):
- `security-auditor` + `test-architect`
- `storage-architect` + `cu-profiler` (on existing code)
- `cross-vm-bridge` + `cadence-deploy` (different files)

**Sequential** — wait for output before spawning next:
- `storage-architect` → `cu-profiler` → `economic-designer`
- `security-auditor` → cadence fix → `security-auditor` (re-audit)
- any writer → `security-auditor` → `cadence-deploy`

## Navigation

| Reference | Content |
|---|---|
| [task-routing.md](references/task-routing.md) | Decision tree: task type → which agents, in which order |
| [handoff-format.md](references/handoff-format.md) | Handoff Block format each agent produces at completion |
