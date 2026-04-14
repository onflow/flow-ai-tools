# Flow AI Tools

AI tools for the [Flow blockchain](https://github.com/onflow) ecosystem. These [Claude Code](https://claude.ai/code) plugins provide domain-specific skills that help Claude Code write better Cadence and Flow code.

## Installation

Add this marketplace to Claude Code:

```bash
/plugin marketplace add onflow/flow-ai-tools
```

Then install individual plugins:

```bash
/plugin install flow-dev@flow-ai-tools
```

## Available Plugins

| Plugin | Description | Skills | Category |
|--------|-------------|--------|----------|
| **flow-dev** | Flow blockchain development | `cadence-lang`, `cadence-tokens`, `cadence-defi-actions`, `cadence-audit`, `cadence-scaffold`, `flow-react-sdk`, `flow-project-setup`, `flow-dev-setup` | blockchain |

### flow-dev

Skills for developing on the Flow blockchain:

| Skill | Description |
|-------|-------------|
| `cadence-lang` | Cadence language fundamentals: access control, entitlements, resources, contracts, transactions, interfaces, accounts, references, capabilities, pre/post conditions, security best practices, anti-patterns, and design patterns |
| `cadence-tokens` | NFT and FT token development: NonFungibleToken/FungibleToken interface conformance, MetadataViews integration, collection patterns, modular NFT architectures |
| `cadence-defi-actions` | DeFi transaction composition using the DeFiActions framework: Source/Sink/Swapper interfaces, IncrementFi connectors, restaking workflows, AutoBalancer |
| `cadence-audit` | Smart contract audit and review: security vulnerabilities, severity-rated findings, structured review format, project-wide audit workflow |
| `cadence-scaffold` | Interactive code generation: scaffold production-ready contracts, transactions, and DeFi transactions with proper security patterns |
| `flow-react-sdk` | React frontend development: FlowProvider setup, Cadence hooks (query, mutate, auth, events), Cross-VM hooks (EVM bridging, batch transactions), UI components (Connect, TransactionButton, NftCard) |
| `flow-project-setup` | Flow project configuration: flow.json setup, FCL frontend integration, CLI workflow, deployment, debugging, gas optimization, testnet validation |
| `flow-dev-setup` | Development environment setup: Flow CLI installation, emulator, VS Code extension, testing framework, dev wallet, frontend SDKs (FCL/React), EVM tooling (Hardhat/Foundry/Remix) |

## Repository Structure

```
.claude-plugin/
    marketplace.json        # Marketplace catalog
plugins/
    flow-dev/
        .claude-plugin/
            plugin.json     # Plugin metadata
        skills/
            cadence-lang/
                SKILL.md    # Cadence language guide
                references/ # 14 reference files
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
            flow-react-sdk/
                SKILL.md    # React SDK guide
                references/ # 4 reference files
            flow-project-setup/
                SKILL.md    # Project setup guide
                references/ # 2 reference files
            flow-dev-setup/
                SKILL.md    # Dev environment setup guide
                references/ # 8 reference files
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
