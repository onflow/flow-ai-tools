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

## Documentation

- Official docs: https://developers.flow.com/tools/flow-cli
- Install guide: https://developers.flow.com/tools/flow-cli/install

For CLI command usage, see the `flow-cli` skill.
