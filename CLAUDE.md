# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

## Project Overview

This repository is a **Claude Code plugin marketplace** for the [Flow blockchain](https://github.com/onflow) ecosystem. It hosts the `cadence` plugin, which provides domain-specific skills that help Claude Code write better, more secure Cadence smart contract code on Flow.

**Target users**: Cadence/Flow developers who install this marketplace into Claude Code to get specialized assistance with smart contract development, auditing, querying, and deployment.

## How Skills Work

Skills use a three-level progressive disclosure system:

1. **Metadata** (~100 words) — The `name` and `description` in YAML frontmatter. Always loaded into Claude's context. This is how Claude decides whether to activate a skill.
2. **SKILL.md body** (~200 words) — Loaded when the skill triggers. Contains overview, quick start, and a navigation map pointing to reference files.
3. **Reference files** (200-300 lines each) — Loaded on demand when Claude needs detailed information on a specific topic.

This design keeps Claude's context efficient: metadata is always present, the skill body loads only when relevant, and references load only when needed for the specific task.

## Repository Structure

```
.claude-plugin/
    marketplace.json            # Marketplace catalog (registers all plugins)
plugins/
    cadence/
        .claude-plugin/
            plugin.json         # Plugin metadata (name, version, author, keywords)
        skills/
            cadence-lang/       # Cadence language fundamentals (13 references)
            cadence-tokens/     # NFT/FT token development (2 references)
            cadence-defi-actions/ # DeFi Actions framework (5 references)
            cadence-audit/      # Security audit & review (2 references)
            cadence-scaffold/   # Code generation templates (3 references)
            flow-cli-query/     # Blockchain data queries (2 references)
            flow-project-setup/ # Project config & deployment (2 references)
README.md                       # Installation instructions and plugin catalog
```

## Skill Routing Guide

When a developer asks for help, use this table to determine which skill(s) to activate:

| Developer need | Primary skill | May also need |
|---|---|---|
| Write/understand Cadence code (syntax, types, patterns) | `cadence-lang` | |
| Build an NFT or FT token contract | `cadence-tokens` | `cadence-lang` |
| Compose DeFi transactions (restaking, swaps, AutoBalancer) | `cadence-defi-actions` | `cadence-lang` |
| Review or audit existing Cadence code | `cadence-audit` | `cadence-lang` |
| Generate a new contract, transaction, or DeFi tx from scratch | `cadence-scaffold` | `cadence-lang`, `cadence-tokens` |
| Query on-chain data (accounts, events, balances, history) | `flow-cli-query` | |
| Set up a Flow project, configure flow.json, deploy | `flow-project-setup` | |

## Key Conventions

### File naming
- Plugin names: kebab-case
- Skill names: kebab-case, unique within a plugin
- Reference files: kebab-case `.md` files in a `references/` subdirectory

### SKILL.md format
Every skill requires YAML frontmatter with:
- `name` — Skill identifier (kebab-case)
- `description` — ~100 words covering: what the skill does, when it should trigger (specific phrases/contexts), and when it should NOT trigger (with redirects to the correct skill)

### Reference files
- 200-300 lines each, focused on a single topic
- If content exceeds 300 lines, split into multiple files rather than truncating
- Include code examples with ✅/❌ patterns where applicable
- All Cadence code examples must follow Cadence 1.0 syntax

### Adding a new skill
1. Create `plugins/cadence/skills/<skill-name>/SKILL.md` with frontmatter
2. Create `references/` subdirectory with topic-focused reference files
3. Update this routing table and the README.md plugin catalog
4. Ensure the description includes trigger phrases AND non-trigger redirects

### Adding a new plugin
1. Create `plugins/<name>/.claude-plugin/plugin.json`
2. Create skills under `plugins/<name>/skills/`
3. Register in `.claude-plugin/marketplace.json`
4. Update README.md

## Content Sources

The skills in this marketplace were derived from:
- [onflow/cadence-rules](https://github.com/onflow/cadence-rules) — Cadence language rules, security patterns, DeFi Actions framework
- [onflow/flow-cli](https://github.com/onflow/flow-cli) — Flow CLI query patterns and FindLabs API
- Flow official documentation — cadence-lang.org, developers.flow.com
- Security audit best practices for Cadence smart contracts
