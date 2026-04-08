# Flow Claude Code Plugins

A [Claude Code](https://claude.ai/code) plugin marketplace for the [Flow blockchain](https://github.com/onflow) ecosystem. These plugins provide domain-specific skills that help Claude Code write better Cadence and Flow code.

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add onflow/flow-claude-code-plugins
```

Then install individual plugins:

```bash
/plugin install cadence@flow-claude-code-plugins
```

## Available Plugins

| Plugin | Description | Skills | Category |
|--------|-------------|--------|----------|
| **cadence** | Cadence smart contract development on Flow | `cadence-lang`, `cadence-tokens`, `cadence-defi-actions`, `cadence-audit`, `cadence-scaffold`, `flow-cli-query`, `flow-project-setup` | blockchain |

### cadence

Skills for writing secure, correct, and idiomatic Cadence code on the Flow blockchain:

| Skill | Description |
|-------|-------------|
| `cadence-lang` | Cadence language fundamentals: access control, entitlements, resources, contracts, transactions, interfaces, accounts, references, capabilities, pre/post conditions, security best practices, anti-patterns, and design patterns |
| `cadence-tokens` | NFT and FT token development: NonFungibleToken/FungibleToken interface conformance, MetadataViews integration, collection patterns, modular NFT architectures |
| `cadence-defi-actions` | DeFi transaction composition using the DeFiActions framework: Source/Sink/Swapper interfaces, IncrementFi connectors, restaking workflows, AutoBalancer |
| `cadence-audit` | Smart contract audit and review: security vulnerabilities, severity-rated findings, structured review format, project-wide audit workflow |
| `cadence-scaffold` | Interactive code generation: scaffold production-ready contracts, transactions, and DeFi transactions with proper security patterns |
| `flow-cli-query` | Querying on-chain data: Flow CLI commands (accounts, blocks, events, transactions, Cadence scripts) and FindLabs historical API (transfer history, NFT holdings, tax reports, node delegation, EVM data) |
| `flow-project-setup` | Flow project configuration: flow.json setup, FCL frontend integration, CLI workflow, deployment, debugging, gas optimization, testnet validation |

## Repository Structure

```
.claude-plugin/
    marketplace.json        # Marketplace catalog
plugins/
    cadence/
        .claude-plugin/
            plugin.json     # Plugin metadata
        skills/
            cadence-lang/
                SKILL.md    # Cadence language guide
                references/ # 13 reference files
            cadence-tokens/
                SKILL.md    # Token development guide
                references/ # 2 reference files
            cadence-defi-actions/
                SKILL.md    # DeFi Actions guide
                references/ # 5 reference files
            cadence-audit/
                SKILL.md    # Audit guide
                references/ # 2 reference files
            cadence-scaffold/
                SKILL.md    # Code generation guide
                references/ # 3 reference files
            flow-cli-query/
                SKILL.md    # Blockchain query guide
                references/ # 2 reference files
            flow-project-setup/
                SKILL.md    # Project setup guide
                references/ # 2 reference files
```

## Contributing

### Adding a new plugin

1. Create a directory under `plugins/<plugin-name>/`
2. Add `.claude-plugin/plugin.json` with plugin metadata:
   ```json
   {
     "name": "your-plugin",
     "description": "What your plugin does",
     "version": "1.0.0",
     "author": { "name": "Your Name" }
   }
   ```
3. Add skills under `skills/<skill-name>/SKILL.md` with YAML frontmatter:
   ```yaml
   ---
   name: your-skill-name
   description: When this skill should be activated
   ---
   ```
4. Register the plugin in `.claude-plugin/marketplace.json` by adding an entry to the `plugins` array
5. Validate with `claude plugin validate .`

### Adding a skill to an existing plugin

1. Create `plugins/<plugin-name>/skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `name` and `description`
3. Write the skill body with patterns, code examples, and common mistakes
