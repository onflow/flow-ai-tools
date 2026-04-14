# Flow CLI — Account Commands

## Get Account

```bash
flow accounts get <address> [flags]
```

Returns address, balance, keys, and deployed contracts.

```bash
# Basic usage
flow accounts get 0xf8d6e0586b0a20c7

# With contract source code
flow accounts get 0xf8d6e0586b0a20c7 --include contracts

# On testnet (JSON output)
flow accounts get 0xf8d6e0586b0a20c7 --network testnet --output json
```

**Output includes**: address, balance, key count, public keys (with weight, sig algo, hash algo, revoked status, sequence number), deployed contract names.

**Key flags**: `--include contracts` to see contract source code.

## Create Account

### Interactive Mode (Recommended)
```bash
flow accounts create
```
Guides through setup. Saves credentials to `flow.json`, stores private keys in `.pkey` files, auto-adds to `.gitignore`.

### Manual Mode
Requires an existing account to pay for creation:
```bash
# First generate a key pair
flow keys generate

# Then create account with the public key
flow accounts create --key <public-key> --signer <payer-account> --network testnet
```

**Key flags:**

| Flag | Purpose | Default |
|------|---------|---------|
| `--key` | Hex-encoded public key | — |
| `--key-weight` | Key weight (0-1000) | 1000 |
| `--sig-algo` | `ECDSA_P256` or `ECDSA_secp256k1` | `ECDSA_P256` |
| `--hash-algo` | `SHA2_256` or `SHA3_256` | `SHA3_256` |
| `--signer` | Payer account name from flow.json | — |
| `--contract` | Deploy contract on creation: `name:filename` | — |

## Fund Account (Testnet Only)

```bash
# By address
flow accounts fund 0x8e94eaa81771313a

# By account name from flow.json
flow accounts fund testnet-account

# Interactive — select from configured accounts
flow accounts fund
```

Opens the Flow Testnet Faucet in browser. Provides 1,000 testnet FLOW tokens. If browser fails, a fallback URL is displayed.

## Staking Info

```bash
flow accounts staking-info <address> [flags]
```

Returns node staking details and delegation information.

```bash
flow accounts staking-info 0x535b975637fb6bee --network mainnet
```

**Output includes**: node ID, initial weight, networking address, role, tokens (committed, staked, rewarded, unstaking, unstaked), delegation details, total stake including delegators.

## Deploy Contract (Add)

```bash
flow accounts add-contract <filename> [args...] [flags]
```

Deploys a contract from a `.cdc` file to an account.

```bash
# Basic (emulator)
flow accounts add-contract ./cadence/contracts/FungibleToken.cdc

# Testnet with signer
flow accounts add-contract ./cadence/contracts/FungibleToken.cdc --signer alice --network testnet

# With init arguments
flow accounts add-contract ./cadence/contracts/MyContract.cdc "Hello" 2

# With JSON arguments
flow accounts add-contract ./MyContract.cdc --args-json '[{"type": "String", "value": "Hello"}]'
```

**Key flags**: `--signer` (required for non-emulator), `--args-json` for complex Cadence types.

## Update Contract

```bash
flow accounts update-contract <filename> [args...] [flags]
```

Updates an existing deployed contract. Same syntax as `add-contract`.

```bash
# Basic update
flow accounts update-contract ./cadence/contracts/FungibleToken.cdc

# With diff preview
flow accounts update-contract ./FungibleToken.cdc --show-diff --signer alice --network testnet
```

**Extra flag**: `--show-diff` displays differences between current and updated contract.

**Upgrade rules**: Can add/change/delete functions, remove fields, reorder fields. Cannot add new fields (init won't re-run), change field types, or remove struct/resource declarations. See `cadence-lang` skill → `contracts.md` for full upgrade rules.

## Remove Contract (Emulator Only)

```bash
flow accounts remove-contract <name> [flags]
```

Removes a deployed contract. **Only works on the emulator** — cannot remove contracts on testnet or mainnet.

```bash
flow accounts remove-contract FungibleToken
flow accounts remove-contract MyContract --signer alice
```

## Common Patterns

### Full Account Setup (Testnet)
```bash
# 1. Create account interactively
flow accounts create

# 2. Fund it
flow accounts fund testnet-account

# 3. Deploy contract
flow accounts add-contract ./cadence/contracts/MyContract.cdc --signer testnet-account --network testnet

# 4. Verify
flow accounts get <new-address> --include contracts --network testnet
```

### Check Balance Across Networks
```bash
flow accounts get 0x1234 --network emulator --output json --filter Balance
flow accounts get 0x1234 --network testnet --output json --filter Balance
flow accounts get 0x1234 --network mainnet --output json --filter Balance
```
