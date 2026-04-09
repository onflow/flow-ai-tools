# Flow Emulator

The Flow Emulator is a local blockchain that emulates the real Flow network. It is bundled with the Flow CLI — no separate installation needed.

## Prerequisites

- Flow CLI installed (see [flow-cli.md](flow-cli.md))

## Starting the Emulator

```bash
flow emulator start
```

Keep this running in a dedicated terminal. All other commands interact with it.

## Default Ports

| Service | Port | URL |
|---------|------|-----|
| gRPC | 3569 | `127.0.0.1:3569` |
| REST API | 8888 | `http://localhost:8888` |
| Admin API | 8080 | `http://localhost:8080` |
| Debugger (DAP) | 2345 | — |

## Key Flags

```bash
# Persist state across restarts
flow emulator start --persist

# Custom state directory
flow emulator start --persist --dbpath ./flowdb

# Set block time (default: manual sealing)
flow emulator start --block-time 1s

# Simple sequential addresses (0x01, 0x02, ...)
flow emulator start --simple-addresses

# Verbose logging
flow emulator start --verbose

# Enable transaction fees
flow emulator start --transaction-fees

# Enable code coverage reporting
flow emulator start --coverage-reporting

# Enable computation cost reporting
flow emulator start --computation-reporting

# Set initial FLOW token supply
flow emulator start --token-supply 1000000000.0
```

## Fork Mode

Test against real mainnet or testnet state locally:

```bash
# Fork from mainnet (default)
flow emulator start --fork

# Fork from testnet
flow emulator start --fork testnet

# Pin to a specific block height
flow emulator start --fork --fork-height 85432100
```

You can also configure fork networks in `flow.json`:
```json
"networks": {
  "mainnet-fork": {
    "host": "127.0.0.1:3569",
    "fork": "mainnet"
  }
}
```

## Snapshots

Save and restore emulator state:

```bash
flow emulator snapshot create my-checkpoint
flow emulator snapshot load my-checkpoint
flow emulator snapshot list
```

Useful for resetting to a known state during development.

## EVM Support

EVM contracts and the VM Bridge are deployed by default. To disable:

```bash
flow emulator start --no-setup-evm
flow emulator start --no-setup-vm-bridge
```

## Debugging

Insert the `#debugger()` pragma in Cadence code to set breakpoints. Connect a DAP-compatible debugger to port 2345.

## Typical Dev Loop

```bash
# Terminal 1: Start emulator
flow emulator start

# Terminal 2: Deploy and interact
flow project deploy
flow scripts execute cadence/scripts/MyScript.cdc
flow transactions send cadence/transactions/MyTx.cdc --signer emulator-account
```

## Documentation

- Official docs: https://developers.flow.com/tools/emulator
