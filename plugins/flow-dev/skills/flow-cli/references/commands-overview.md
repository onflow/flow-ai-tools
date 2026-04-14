# Flow CLI — Command Overview

## Installation

### macOS
```bash
brew install flow-cli          # Install
brew upgrade flow-cli          # Upgrade
brew uninstall flow-cli        # Uninstall
```

### Linux
```bash
sudo sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"
# Uninstall: rm ~/.local/bin/flow
```

### Windows (PowerShell)
```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/onflow/flow-cli/master/install.ps1') }"
```

## Full Command Reference

### Project Lifecycle
| Command | Purpose |
|---------|---------|
| `flow init [name]` | Initialize new project |
| `flow init --config-only` | Create only flow.json |
| `flow generate contract <Name>` | Generate contract scaffold |
| `flow generate script <Name>` | Generate script scaffold |
| `flow generate transaction <Name>` | Generate transaction scaffold |
| `flow generate test <Name>` | Generate test scaffold |
| `flow test` | Run all Cadence tests |
| `flow test --coverage` | Run tests with coverage |
| `flow test --verbose` | Run tests with detailed output |
| `flow project deploy` | Deploy to emulator (default) |
| `flow project deploy --network=testnet` | Deploy to testnet |
| `flow project deploy --update` | Update existing contracts |

### Account Management
| Command | Purpose |
|---------|---------|
| `flow accounts get <address>` | Get account info |
| `flow accounts create` | Create account (interactive) |
| `flow accounts create --key <key>` | Create account (manual) |
| `flow accounts fund [address\|name]` | Fund testnet account via faucet |
| `flow accounts list` | List configured accounts |
| `flow accounts staking-info <address>` | Get staking details |
| `flow accounts add-contract <file>` | Deploy contract to account |
| `flow accounts update-contract <file>` | Update deployed contract |
| `flow accounts remove-contract <name>` | Remove contract (emulator only) |

### Scripts & Transactions
| Command | Purpose |
|---------|---------|
| `flow scripts execute <file.cdc> [args]` | Execute Cadence script |
| `flow transactions send <file.cdc> [args]` | Send transaction |
| `flow transactions get <txId>` | Get transaction details |
| `flow transactions get-system <block>` | Get system transaction |
| `flow transactions profile <txId>` | Profile transaction performance |

### Keys
| Command | Purpose |
|---------|---------|
| `flow keys generate` | Generate new key pair |
| `flow keys decode <key>` | Decode public key |
| `flow keys derive <private-key>` | Derive public from private |

### Dependencies
| Command | Purpose |
|---------|---------|
| `flow dependencies install <source>` | Install contract dependency |
| `flow dependencies list` | List installed dependencies |
| `flow dependencies discover` | Discover available deps |

### Configuration
| Command | Purpose |
|---------|---------|
| `flow config add account` | Add account to flow.json |
| `flow config add contract` | Add contract to flow.json |
| `flow config add deployment` | Add deployment target |
| `flow config remove <type> <name>` | Remove config entry |
| `flow config validate` | Validate flow.json |

### Scheduled Transactions
| Command | Purpose |
|---------|---------|
| `flow schedule setup` | Initialize scheduler resource |
| `flow schedule list <account>` | List scheduled transactions |
| `flow schedule get <id>` | Get scheduled tx details |
| `flow schedule cancel <id>` | Cancel scheduled tx |

### Development
| Command | Purpose |
|---------|---------|
| `flow emulator` | Start local emulator |
| `flow cadence lint` | Lint Cadence code |

## Global Flags

These flags work with most commands:

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `--network` | `-n` | Target network | `emulator` |
| `--host` | | Access API hostname | `127.0.0.1:3569` |
| `--output` | `-o` | Output format: `json`, `inline` | text |
| `--filter` | `-x` | Return specific property only | |
| `--save` | `-s` | Save output to file | |
| `--log` | `-l` | Log level: `none`, `error`, `debug`, `info` | `info` |
| `--config-path` | `-f` | Path to flow.json | `flow.json` |
| `--skip-version-check` | | Skip CLI version check | `false` |
| `--network-key` | | Network public key (hex) | |

## Output Options

```bash
# Machine-readable JSON
flow accounts get 0x1234 --output json --network mainnet

# Filter specific field
flow accounts get 0x1234 --filter Balance --network mainnet

# Save to file
flow accounts get 0x1234 --output json --save account.json --network mainnet
```

## Network Shortcuts

```bash
--network emulator    # Local (default) — 127.0.0.1:3569
--network testnet     # Testnet — access.devnet.nodes.onflow.org:9000
--network mainnet     # Mainnet — access.mainnet.nodes.onflow.org:9000
```
