# Flow CLI

The Flow CLI is the core tool for all Flow development. It includes the emulator, dev wallet, project management, contract deployment, transaction execution, and testing.

## Installation

### macOS (Homebrew — recommended)
```bash
brew install flow-cli
```

### macOS/Linux (install script)
```bash
sudo sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"
```

To install a specific version:
```bash
sudo sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)" -- v2.0.0
```

### Windows (PowerShell)
```powershell
iex "& { $(irm 'https://raw.githubusercontent.com/onflow/flow-cli/master/install.ps1') }"
```

## Verify Installation

```bash
flow version
```

Expected output includes the CLI version, Cadence version, and Go version.

## Upgrade

```bash
# Homebrew
brew upgrade flow-cli

# macOS/Linux script — re-run the install script
sudo sh -ci "$(curl -fsSL https://raw.githubusercontent.com/onflow/flow-cli/master/install.sh)"

# Windows — re-run the PowerShell command
```

Note: Homebrew cannot install earlier versions. Use the install script for version pinning.

## Uninstall

```bash
# Homebrew
brew uninstall flow-cli

# macOS binary
rm /usr/local/bin/flow

# Linux binary
rm ~/.local/bin/flow

# Windows
rm ~/Users/{user}/AppData/Flow/flow.exe
```

## Initialize a Project

```bash
flow init                  # Interactive — prompts for name and template
flow init my-project       # Create project in new directory
flow init --config-only    # Only create flow.json, no scaffolding
```

This creates the standard project structure:
```
my-project/
  flow.json
  emulator-account.pkey
  cadence/
    contracts/
    scripts/
    transactions/
    tests/
```

## Generate Boilerplate

```bash
flow generate contract MyToken
flow generate script GetBalance
flow generate transaction TransferTokens
flow generate test MyToken
```

## Key Management

```bash
flow keys generate                    # Generate a new key pair
flow keys decode <public-key>         # Decode a public key
flow keys derive <mnemonic>           # Derive key from mnemonic
```

## Account Management

```bash
flow accounts create                              # Interactive account creation
flow accounts create --network testnet             # Create on testnet
flow accounts fund --network testnet <account>     # Fund testnet account from faucet
flow accounts get <address>                        # Get account details
```

## Essential Commands

```bash
# Contract deployment
flow project deploy                          # Deploy to emulator (default)
flow project deploy --network=testnet        # Deploy to testnet

# Scripts and transactions
flow scripts execute cadence/scripts/MyScript.cdc
flow transactions send cadence/transactions/MyTx.cdc --signer my-account

# Dependencies
flow dependencies install                    # Install dependencies from flow.json
flow dependencies install testnet://0x123.ContractName   # Install specific dependency

# Configuration
flow config add account
flow config add deployment
flow config validate
```

## Documentation

- Official docs: https://developers.flow.com/tools/flow-cli
- Install guide: https://developers.flow.com/tools/flow-cli/install
