# Cadence MCP Server

The Cadence MCP (Model Context Protocol) server gives AI coding agents direct access to Cadence tooling — type checking, code review, on-chain contract inspection, and script execution. It is built into the Flow CLI.

## Prerequisites

- Flow CLI installed (see [flow-cli.md](flow-cli.md))

## Setup

### Claude Code
```bash
claude mcp add cadence-mcp -- flow mcp
```

### Cursor / Claude Desktop
Add to your MCP settings JSON:
```json
{
  "mcpServers": {
    "cadence-mcp": {
      "command": "flow",
      "args": ["mcp"]
    }
  }
}
```

## Available Tools

| Tool | Purpose |
|------|---------|
| `cadence_check` | Check Cadence code for syntax and type errors |
| `cadence_hover` | Get type info for a symbol at a position |
| `cadence_definition` | Find where a symbol is defined |
| `cadence_symbols` | List all symbols in Cadence code |
| `cadence_completion` | Get completions at a position |
| `get_contract_source` | Fetch on-chain contract manifest from an address |
| `get_contract_code` | Fetch contract source code from an address |
| `cadence_code_review` | Review Cadence code for common issues |
| `cadence_execute_script` | Execute a read-only Cadence script on-chain |

## Network Configuration

By default the MCP server connects to the emulator. To target a different network:

```json
{
  "mcpServers": {
    "cadence-mcp": {
      "command": "flow",
      "args": ["mcp", "--network", "testnet"]
    }
  }
}
```

Valid networks: `emulator`, `testnet`, `mainnet`.

## What Agents Can Do With It

- **Check code before deploying** — `cadence_check` catches syntax and type errors without needing to deploy
- **Inspect deployed contracts** — `get_contract_source` and `get_contract_code` let agents read any on-chain contract
- **Review for security issues** — `cadence_code_review` flags common Cadence anti-patterns
- **Execute read-only queries** — `cadence_execute_script` runs scripts against live network state
- **Navigate code** — `cadence_hover`, `cadence_definition`, and `cadence_symbols` provide IDE-like navigation
