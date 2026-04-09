# Flow CLI — Project Commands

## Initialize Project

```bash
flow init my-project          # Full project with templates
flow init --config-only       # Only create flow.json
flow init --global            # Global configuration
```

Creates: `flow.json`, `cadence/` directory structure (contracts, scripts, transactions, tests), emulator account key file, example files.

Template options include scheduled transactions, DeFi applications, and stablecoins.

## Generate Scaffolds

```bash
flow generate contract MyToken           # cadence/contracts/MyToken.cdc
flow generate script GetBalance          # cadence/scripts/GetBalance.cdc
flow generate transaction TransferTokens # cadence/transactions/TransferTokens.cdc
flow generate test MyToken               # cadence/tests/MyToken_test.cdc
```

## Run Tests

```bash
flow test                                    # Run all tests
flow test cadence/tests/MyToken_test.cdc     # Run specific test
flow test --coverage                         # With coverage report
flow test --verbose                          # Detailed output
```

## Deploy Contracts

```bash
# Deploy to emulator (default)
flow project deploy

# Deploy to testnet
flow project deploy --network=testnet

# Deploy to mainnet
flow project deploy --network=mainnet

# Update existing contracts
flow project deploy --update

# Deploy with specific signer
flow project deploy --network=testnet --signer testnet-deployer
```

Reads `deployments` section of `flow.json` to determine which contracts go to which accounts.

## Execute Scripts

```bash
# Basic script execution
flow scripts execute cadence/scripts/GetBalance.cdc

# With positional arguments (simple types)
flow scripts execute cadence/scripts/GetBalance.cdc 0xf8d6e0586b0a20c7

# With JSON arguments (complex types)
flow scripts execute cadence/scripts/GetBalance.cdc \
  --args-json '[{"type": "Address", "value": "0xf8d6e0586b0a20c7"}]'

# On specific network
flow scripts execute cadence/scripts/GetBalance.cdc --network testnet

# At historical block height
flow scripts execute cadence/scripts/GetBalance.cdc --block-height 12345 --network mainnet

# At specific block ID
flow scripts execute cadence/scripts/GetBalance.cdc --block-id abc123... --network mainnet
```

Simple types (Address, UInt64, String, Bool) can be positional args. Use `--args-json` for UFix64, optionals, structs, arrays, dictionaries.

## Send Transactions

```bash
# Basic transaction
flow transactions send cadence/transactions/TransferTokens.cdc

# With arguments
flow transactions send cadence/transactions/Transfer.cdc \
  --arg Address:0xf8d6e0586b0a20c7 --arg UFix64:10.0

# With JSON arguments
flow transactions send cadence/transactions/Transfer.cdc \
  --args-json '[{"type": "Address", "value": "0x1234"}, {"type": "UFix64", "value": "10.0"}]'

# With specific signer and network
flow transactions send cadence/transactions/Setup.cdc --signer testnet-account --network testnet

# With gas limit
flow transactions send cadence/transactions/HeavyTx.cdc --gas-limit 9999
```

## Transaction Inspection

```bash
# Get transaction details
flow transactions get <txId> --network mainnet

# Include signatures, code, fee events
flow transactions get <txId> --include signatures,code,fee-events --network mainnet

# Get system transaction for a block
flow transactions get-system latest --network mainnet
flow transactions get-system 12884163 --network mainnet

# Profile transaction performance
flow transactions profile <txId> --network mainnet
flow transactions profile <txId> --output my-profile.pb.gz --network testnet
```

## Dependency Management

```bash
# Install from testnet
flow dependencies install testnet://8a4dce54554b225d.NumberFormatter

# Install from mainnet
flow dependencies install mainnet://f233dcee88fe0abe.FungibleToken

# Install with specific account
flow dependencies install testnet://8a4dce54554b225d.NumberFormatter --account my-account

# List and discover
flow dependencies list
flow dependencies discover
```

## Configuration Management

```bash
# Add items
flow config add account --name my-account --address 0x123 --private-key abc123
flow config add contract --name MyToken --filename ./cadence/contracts/MyToken.cdc
flow config add deployment --network testnet --account my-account --contract MyToken

# Remove items
flow config remove account my-account
flow config remove contract MyToken
flow config remove deployment testnet my-account MyToken

# Validate
flow config validate
```

## Scheduled Transactions

```bash
# Setup scheduler resource (one-time per account)
flow schedule setup --network testnet --signer my-account

# List scheduled transactions
flow schedule list my-account --network testnet

# Get details for specific scheduled tx
flow schedule get 123 --network testnet

# Cancel a scheduled transaction
flow schedule cancel 123 --network testnet --signer my-account
```

## Key Management

```bash
# Generate new key pair
flow keys generate

# Decode a public key
flow keys decode <encoded-key>

# Derive public key from private
flow keys derive <private-key>
```

## Emulator

```bash
# Start emulator
flow emulator

# Start with persistence
flow emulator --persist

# Start with specific port
flow emulator --port 3570
```

The emulator provides a local Flow blockchain for development. Default service account: `0xf8d6e0586b0a20c7`.

## Code Quality

```bash
# Lint Cadence files
flow cadence lint
```

## Common Workflow

```bash
# 1. Initialize
flow init my-project && cd my-project

# 2. Start emulator (in separate terminal)
flow emulator

# 3. Deploy and test locally
flow project deploy
flow test

# 4. Create testnet account and fund it
flow accounts create
flow accounts fund testnet-account

# 5. Deploy to testnet
flow project deploy --network=testnet

# 6. Verify deployment
flow accounts get <address> --include contracts --network testnet

# 7. Run scripts against testnet
flow scripts execute cadence/scripts/GetBalance.cdc --network testnet
```

> **See also:** `cadence-lang` skill for Cadence syntax when writing scripts and transactions. `cadence-scaffold` skill to generate contract/transaction files. `flow-project-setup` skill for flow.json configuration and deployment strategy. `cadence-audit` skill to review code before deploying to testnet/mainnet.
