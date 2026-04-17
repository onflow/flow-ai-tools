# Flow CLI — Query Blockchain

## Decision Table

| What you need | Command |
|---------------|---------|
| Account info, balance, keys, contracts | `flow accounts get <address>` |
| Latest or specific block | `flow blocks get latest` / `flow blocks get <id-or-height>` |
| Events by type in block range | `flow events get <EventType> --start <start> --end <end>` |
| Collection by ID | `flow collections get <collectionID>` |
| Transaction by ID | `flow transactions get <txID>` |
| System transaction for a block | `flow transactions get-system <block>` |
| Execute read-only Cadence script | `flow scripts execute <file.cdc> [args]` |
| Historical script at block height | `flow scripts execute <file.cdc> --block-height <N>` |
| Historical script at block ID | `flow scripts execute <file.cdc> --block-id <id>` |

---

## Commands

### `flow accounts get`

```bash
# Basic — shows balance, keys, and contracts
flow accounts get 0xf8d6e0586b0a20c7 --network mainnet

# Include specific fields
flow accounts get 0xf8d6e0586b0a20c7 --include contracts --network mainnet

# JSON output for scripting
flow accounts get 0xf8d6e0586b0a20c7 --output json --network mainnet

# Filter to single field
flow accounts get 0xf8d6e0586b0a20c7 --filter Balance --network mainnet
```

**Output fields:** `Address`, `Balance` (FLOW in UFix64), `Keys` (index, weight, algorithm), `Contracts` (name → code hash).

---

### `flow blocks get`

```bash
# Latest block
flow blocks get latest --network mainnet

# By block height
flow blocks get 12884163 --network mainnet

# By block ID
flow blocks get abc123def456... --network mainnet

# JSON output
flow blocks get latest --output json --network mainnet
```

**Output fields:** `BlockID`, `ParentID`, `Height`, `Timestamp`, `CollectionGuarantees`, `Seals`, `PayloadHash`.

---

### `flow events get`

```bash
# Events in block range (inclusive) — use --start and --end flags
flow events get A.1654653399040a61.FlowToken.TokensWithdrawn --start 0 --end 100 --network mainnet

# With JSON output
flow events get "A.f233dcee88fe0abe.FungibleToken.TokensDeposited" \
  --start 15000000 --end 15000100 --network mainnet --output json
```

**Event type format:** `A.<contract-address>.<ContractName>.<EventName>`

---

### `flow collections get`

```bash
flow collections get <collectionID> --network mainnet
```

**Output:** Transaction IDs included in the collection.

---

### `flow transactions get`

```bash
# Basic
flow transactions get <txID> --network mainnet

# Include signatures and code (valid values: code, payload, signatures)
flow transactions get <txID> --include signatures,code --network mainnet

# JSON
flow transactions get <txID> --output json --network mainnet
```

**Output fields:** `Status`, `ID`, `Payer`, `Authorizers`, `Proposal Key`, `Payload Signatures`, `Envelope Signatures`, `Events`, `Arguments`, `Error` (if failed).

---

### `flow transactions get-system`

```bash
# System transaction for latest block
flow transactions get-system latest --network mainnet

# System transaction for specific block height
flow transactions get-system 12884163 --network mainnet
```

System transactions are protocol-level (epoch transitions, slashing, etc.) — not user-submitted.

---

### `flow scripts execute`

```bash
# Simple address argument
flow scripts execute cadence/scripts/GetBalance.cdc 0xf8d6e0586b0a20c7 --network mainnet

# JSON arguments (required for UFix64, arrays, structs, optionals)
flow scripts execute cadence/scripts/GetNFTs.cdc \
  --args-json '[{"type": "Address", "value": "0xf8d6e0586b0a20c7"}]' \
  --network mainnet

# At historical block height
flow scripts execute cadence/scripts/GetBalance.cdc 0xf8d6e0586b0a20c7 \
  --block-height 12000000 --network mainnet

# At specific block ID
flow scripts execute cadence/scripts/GetBalance.cdc 0xabc123... \
  --block-id def456... --network mainnet
```

**Argument type mapping for `--args-json`:**

| Cadence type | JSON type value |
|-------------|-----------------|
| `Address` | `"Address"` |
| `String` | `"String"` |
| `UInt64` | `"UInt64"` |
| `UFix64` | `"UFix64"` |
| `Bool` | `"Bool"` |
| `Optional<T>` | `"Optional"` with nested value |
| `[T]` | `"Array"` with items array |
| `{K: V}` | `"Dictionary"` with key/value pairs |

---

## Standard Contract Addresses

Core Flow contracts across environments:

| Contract | Mainnet | Testnet | Emulator |
|----------|---------|---------|----------|
| `FungibleToken` | `0xf233dcee88fe0abe` | `0x9a0766d93b6608b7` | `0xee82856bf20e2aa6` |
| `FlowToken` | `0x1654653399040a61` | `0x7e60df042a9c0868` | `0x0ae53cb6e3f42a79` |
| `NonFungibleToken` | `0x1d7e57aa55817448` | `0x631e88ae7f1d7c20` | `0xf8d6e0586b0a20c7` |
| `MetadataViews` | `0x1d7e57aa55817448` | `0x631e88ae7f1d7c20` | `0xf8d6e0586b0a20c7` |
| `NFTStorefrontV2` | `0x4eb8a10cb9f87357` | `0x2d55b98eb200daef` | — |
| `FlowIDTableStaking` | `0x8624b52f9ddcd04a` | `0x9eca2b38b18b5dfe` | `0xf8d6e0586b0a20c7` |
| `FlowEpoch` | `0x8624b52f9ddcd04a` | `0x9eca2b38b18b5dfe` | `0xf8d6e0586b0a20c7` |
| `FlowClusterQC` | `0x8624b52f9ddcd04a` | `0x9eca2b38b18b5dfe` | `0xf8d6e0586b0a20c7` |
| `FlowDKG` | `0x8624b52f9ddcd04a` | `0x9eca2b38b18b5dfe` | `0xf8d6e0586b0a20c7` |
| `FlowServiceAccount` | `0xe467b9dd11fa00df` | `0x8c5303eaa26202d6` | `0xf8d6e0586b0a20c7` |
| `FlowFees` | `0xf919ee77447b7497` | `0x912d5440f7e3769e` | `0xe5a8b7f23e8b548f` |
| `FlowStorageFees` | `0xe467b9dd11fa00df` | `0x8c5303eaa26202d6` | `0xf8d6e0586b0a20c7` |
| `Crypto` | `0xe467b9dd11fa00df` | `0x8c5303eaa26202d6` | `0xf8d6e0586b0a20c7` |
| `EVM` | `0xe467b9dd11fa00df` | `0x8c5303eaa26202d6` | `0xf8d6e0586b0a20c7` |
| `FlowEVMBridge` | `0x1e4aa0b87d10b141` | `0xdfc20aee650fcbdf` | — |
| `HybridCustody` | `0xd8a7e05a7ac670c0` | `0x294e44e1ec6993c6` | — |
| `CapabilityFactory` | `0xd8a7e05a7ac670c0` | `0x294e44e1ec6993c6` | — |
| `CapabilityFilter` | `0xd8a7e05a7ac670c0` | `0x294e44e1ec6993c6` | — |
| `ViewResolver` | `0x1d7e57aa55817448` | `0x631e88ae7f1d7c20` | `0xf8d6e0586b0a20c7` |
| `Burner` | `0xf233dcee88fe0abe` | `0x9a0766d93b6608b7` | `0xee82856bf20e2aa6` |
| `FungibleTokenMetadataViews` | `0xf233dcee88fe0abe` | `0x9a0766d93b6608b7` | `0xee82856bf20e2aa6` |
| `FungibleTokenSwitchboard` | `0xf233dcee88fe0abe` | `0x9a0766d93b6608b7` | `0xee82856bf20e2aa6` |
| `RandomBeaconHistory` | `0xe467b9dd11fa00df` | `0x8c5303eaa26202d6` | `0xf8d6e0586b0a20c7` |
| `NodeVersionBeacon` | `0xe467b9dd11fa00df` | `0x8c5303eaa26202d6` | `0xf8d6e0586b0a20c7` |
| `AccountCreationReserve` | `0xe467b9dd11fa00df` | `0x8c5303eaa26202d6` | — |
| `StakingCollection` | `0x8d0e87b65159ae63` | `0x95e019a17d0e23d7` | — |

> **In Cadence code**, always use string imports (`import "FungibleToken"`) with flow.json contract aliases rather than hardcoding addresses.

> **See also:** `cadence-scripts.md` for ready-to-use scripts for common queries.
