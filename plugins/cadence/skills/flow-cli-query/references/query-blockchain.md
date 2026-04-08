# Querying the Flow Blockchain with flow-cli

## Decision Table

| What you need | Command |
|---|---|
| Account balance, keys, deployed contracts | `flow accounts get` |
| Block info | `flow blocks get` |
| Events emitted in a block range | `flow events get` |
| Transaction status/result | `flow transactions get` |
| System transaction for a block | `flow transactions get-system` |
| Scheduled transaction details | `flow schedule get` / `flow schedule list` |
| Collection contents | `flow collections get` |
| Anything not covered above | `flow scripts execute` |

## Commands

### Accounts
```bash
flow accounts get <address> [--include contracts] [--network mainnet]
```
- Flow addresses must include `0x` prefix
- `--include contracts` adds deployed contract source code
- `--output json` for machine-readable output

### Blocks
```bash
flow blocks get <block_id|latest|block_height> [--include transactions] [--events <event_name>] [--network mainnet]
```

### Events
```bash
flow events get <event_name> [--last 10] [--start N --end M] [--network mainnet]
```
- Event name format: `A.<address>.<ContractName>.<EventName>`
- Default: last 10 blocks. Use `--last N` to widen.
- Multiple event types fetched in parallel.

```bash
flow events get A.1654653399040a61.FlowToken.TokensDeposited --last 20 --network mainnet
flow events get A.1654653399040a61.FlowToken.TokensDeposited --start 11559500 --end 11559600 --network mainnet
```

### Transactions
```bash
flow transactions get <tx_id> [--include signatures,code,payload,fee-events] [--exclude events] [--network mainnet]
```
- `--include` accepts comma-separated values — combine into one call
- Alias: `flow transactions status <tx_id>`

#### System Transactions
```bash
flow transactions get-system <block_id|latest|block_height> [tx_id] [--network mainnet]
```
First arg is block reference, not a transaction hash.

#### Scheduled Transactions
```bash
flow schedule get <numeric-id> [--network mainnet]
flow schedule list <address|account-name> [--network mainnet]
```
Returns: ID, status, priority, execution effort, fees, scheduled timestamp, handler type/address.

### Collections
```bash
flow collections get <collection_id> [--network mainnet]
```

## Cadence Scripts

Use `flow scripts execute` when entity commands don't expose what you need. This is the most powerful read tool.

```bash
flow scripts execute <script.cdc> [args...] [--args-json '[{"type":"...","value":"..."}]'] [--block-height N] [--network mainnet]
```

- Simple types as positional args; `--args-json` for complex types
- `--block-height` / `--block-id` for historical state queries

### Common Contract Repos

| Repo | Contains | Use for |
|---|---|---|
| [flow-core-contracts](https://github.com/onflow/flow-core-contracts) | FlowToken, FlowFees, FlowIDTableStaking, FlowEpoch, LockedTokens | Protocol queries: staking, epochs, fees |
| [flow-ft](https://github.com/onflow/flow-ft) | FungibleToken, FungibleTokenMetadataViews, Burner | FT balances, vault state |
| [flow-nft](https://github.com/onflow/flow-nft) | NonFungibleToken, MetadataViews, ViewResolver | NFT ownership, metadata |
| [flow-evm-bridge](https://github.com/onflow/flow-evm-bridge) | Bridge contracts (Cadence ↔ EVM) | Bridge state, onboarded assets |

### Standard Mainnet Addresses
```cadence
import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
```

### Pattern: Write Script, Execute, Clean Up
```bash
cat > /tmp/query.cdc << 'EOF'
import FungibleToken from 0xf233dcee88fe0abe
import FlowToken from 0x1654653399040a61

access(all) fun main(address: Address): UFix64 {
    let account = getAccount(address)
    let vaultRef = account.capabilities
        .borrow<&{FungibleToken.Balance}>(/public/flowTokenBalance)
        ?? panic("Could not borrow balance capability")
    return vaultRef.balance
}
EOF

flow scripts execute /tmp/query.cdc 0xf8d6e0586b0a20c7 --network mainnet
rm /tmp/query.cdc
```

### Historical State Query
```bash
flow scripts execute /tmp/query.cdc 0xf8d6e0586b0a20c7 --block-height 12884163 --network mainnet
```

## Output
All commands accept `--output json` for machine-readable output.
