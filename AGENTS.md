# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, Codex, Cursor, Copilot, and others)
when working in this repository. It is loaded into agent context automatically — keep it concise.

## Overview

This repository is a Claude Code plugin marketplace for the Flow blockchain ecosystem. It ships
one plugin, `flow-dev`, containing ten skills that provide domain knowledge for Cadence and Flow
development. Content is Markdown only — there is no code to build, compile, or test.

## Repository Layout

```
.claude-plugin/marketplace.json          Marketplace catalog, registers plugins
plugins/flow-dev/
    .claude-plugin/plugin.json           Plugin metadata
    skills/<skill-name>/
        SKILL.md                         Skill entry point with YAML frontmatter
        references/                      Topic-focused markdown loaded on demand
scripts/install.sh                       One-liner installer (Flow CLI + MCP + plugin)
CLAUDE.md                                Full authoring guide for contributors
README.md                                User-facing install + skill catalog
CODEOWNERS                               @onflow/flow-engineering owns everything
```

## Plugin and Skills

One plugin is registered in `.claude-plugin/marketplace.json`:

- **flow-dev** (`plugins/flow-dev/`) — v1.0.0, category `blockchain`

It contains exactly these ten skills (each has its own `SKILL.md` plus a `references/` directory):

| Skill | Reference count |
|---|---|
| `cadence-lang` | 14 |
| `cadence-tokens` | 3 |
| `cadence-audit` | 2 |
| `cadence-scaffold` | 3 |
| `flow-react-sdk` | 4 |
| `flow-project-setup` | 2 |
| `flow-cli` | 5 |
| `flow-dev-setup` | 8 |
| `flow-defi` | 4 |
| `flow-tokenomics` | 5 |

Descriptions and trigger phrases live in each `SKILL.md` frontmatter. The routing table in
`CLAUDE.md` maps developer intents to primary skills.

## Install and Validate Commands

There is no build or test target. Validate structural changes with:

- `claude plugin validate .` — schema-validates `marketplace.json` and each `plugin.json`
  (documented in `README.md` § Contributing).

End-user install flow (from `scripts/install.sh` and `README.md`):

- `sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-ai-tools/main/scripts/install.sh)"`
- `/plugin marketplace add onflow/flow-ai-tools` then `/plugin install flow-dev@flow-ai-tools`
- `claude mcp add --scope user cadence-mcp -- flow mcp` (Cadence MCP, added by `install.sh`)

## Conventions and Gotchas

- **No code, only Markdown.** Every change is to `.md` files, `marketplace.json`, or
  `plugin.json`. There is no language toolchain in this repo.
- **Kebab-case names.** Plugin and skill directory names must be kebab-case and match the
  `name` field in their respective `plugin.json` / SKILL.md frontmatter.
- **SKILL.md frontmatter is required.** Each skill needs YAML with `name` and `description`.
  The `description` must include both trigger phrases and (when relevant) non-trigger
  redirects to the correct skill — see existing skills for the pattern.
- **Reference files stay 200–300 lines.** Per `CLAUDE.md`: if a topic exceeds 300 lines,
  split into multiple files rather than truncating.
- **Cadence 1.0 syntax only.** All Cadence code examples in skill content must follow
  Cadence 1.0 (`CLAUDE.md` § Reference files).
- **Register a new skill in three places.** Create `SKILL.md` + `references/`, update the
  routing table in `CLAUDE.md`, update the skill catalog in `README.md`.
- **Register a new plugin in four places.** Create `plugins/<name>/.claude-plugin/plugin.json`,
  add skills under `skills/`, add an entry to the `plugins` array in
  `.claude-plugin/marketplace.json`, update `README.md`.
- **`.gitignore` excludes `.claude` and `docs/plans/`.** Don't commit local Claude state or
  planning documents.
- **Ownership.** `CODEOWNERS` routes every path to `@onflow/flow-engineering`.

## Files Not to Modify

- `scripts/install.sh` — public one-liner endpoint referenced from the README; breaking
  changes affect existing users running the curl command.
</content>
</invoke>