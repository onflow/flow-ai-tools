# Querying Flow with findapi (FindLabs Historical API)

`findapi` provides data standard Flow nodes don't expose: full transfer history, token holdings, tax reports, and more.

## Setup
```bash
go install github.com/peterargue/find-api/cmd/findapi@latest
findapi auth login  # Interactive; token stored at ~/.config/find-cli/token.json, valid 7 days
```

## findapi vs flow-cli

| Need | Tool |
|---|---|
| Current account balance, keys, contracts | `flow-cli` |
| Full token transfer history | `findapi` |
| NFT holdings across all collections | `findapi` |
| Tax report (all inflows/outflows) | `findapi` |
| Events in recent block range | `flow-cli` |
| Events across large historical range | `findapi` |
| Node delegation rewards | `findapi` |
| Contract registry / by-identifier lookup | `findapi` |
| EVM token/transaction data | `findapi` |

## Decision Table

| What you need | Command |
|---|---|
| Recent blocks | `findapi blocks list` |
| Specific block | `findapi blocks get` |
| Account profile + Find name | `findapi accounts get` |
| FT holdings for account | `findapi accounts ft-holdings` |
| FT transfer history | `findapi accounts ft-transfers` |
| NFT holdings for account | `findapi accounts nft` |
| NFT item list | `findapi accounts nft-items` |
| Tax report | `findapi accounts tax-report` |
| Transaction list for account | `findapi accounts tx` |
| All FT collections (catalog) | `findapi ft list` |
| FT transfers (global/filtered) | `findapi ft transfers` |
| All NFT collections (catalog) | `findapi nft list` |
| NFT transfers | `findapi nft transfers` |
| Single NFT item details | `findapi nft item` |
| Transaction details | `findapi transactions get` |
| Scheduled transactions | `findapi transactions scheduled` |
| Node list / details | `findapi nodes list` / `findapi nodes get` |
| Delegation rewards | `findapi nodes delegation-rewards` |
| Contract list / lookup | `findapi contracts list` / `findapi contracts by-identifier` |
| EVM tokens / transactions | `findapi evm tokens` / `findapi evm transactions` |

## Commands

### Blocks
```bash
findapi blocks list [--height <n>] [--limit <n>] [--offset <n>]
findapi blocks get <block_id|block_height>
findapi blocks service-events <block_id_or_height>
findapi blocks transactions <block_id_or_height>
```

### Accounts
```bash
findapi accounts get <address>
findapi accounts ft-holdings <address> [--limit <n>]
findapi accounts ft-transfers <address> [--limit <n>]
findapi accounts ft-token-transfers <address> <token_type> [--limit <n>]
findapi accounts nft <address> [--limit <n>]
findapi accounts nft-items <address> [--limit <n>]
findapi accounts tx <address> [--limit <n>]
findapi accounts tax-report <address> [--height <n>] [--limit <n>]
```

### Fungible Tokens
```bash
findapi ft list [--limit <n>]
findapi ft get <token_type>                                    # e.g. A.1654653399040a61.FlowToken
findapi ft transfers [--address <addr>] [--token-type <type>] [--height <n>] [--limit <n>]
findapi ft holdings [--address <addr>] [--token-type <type>] [--limit <n>]
```

### NFTs
```bash
findapi nft list [--limit <n>]
findapi nft get <collection_type>                              # e.g. A.0b2a3299cc857e29.TopShot
findapi nft transfers [--address <addr>] [--nft-type <type>] [--height <n>] [--limit <n>]
findapi nft holdings [--address <addr>] [--nft-type <type>] [--limit <n>]
findapi nft item <collection_type> <nft_id>
```

### Transactions
```bash
findapi transactions list [--limit <n>]
findapi transactions get <tx_id>
findapi transactions scheduled [--limit <n>]
```

### Nodes
```bash
findapi nodes list [--limit <n>]
findapi nodes get <node_id>
findapi nodes delegation-rewards <node_id> [--limit <n>]
```

### Contracts
```bash
findapi contracts list [--limit <n>]
findapi contracts by-identifier <cadence_identifier>
findapi contracts get <cadence_identifier>
```

### EVM
```bash
findapi evm tokens [--limit <n>]
findapi evm token <token_address>
findapi evm transactions [--limit <n>]
findapi evm transaction <tx_hash>
```

## Output Flags

| Flag | Description |
|---|---|
| `--format json` | Machine-readable JSON |
| `--format oneliner` | Single-line summary |
| `--filter <expr>` | Filter output |
| `--save <file>` | Write output to file |

```bash
findapi accounts ft-holdings 0xf8d6e0586b0a20c7 --format json
findapi nft transfers --address 0xf8d6e0586b0a20c7 --format json --save /tmp/transfers.json
```
