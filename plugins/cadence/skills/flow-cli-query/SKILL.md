---
name: flow-cli-query
description: |
  Guide for querying on-chain data from the Flow blockchain using the Flow CLI and the FindLabs historical API (findapi). Covers accounts, blocks, events, transactions, collections, Cadence scripts, token transfer history, NFT holdings, tax reports, node delegation, EVM data, and contract lookups.
  TRIGGER when: querying blockchain data, checking account balances, looking up transactions, fetching events, reading on-chain state, checking NFT ownership, getting transfer history, "check balance", "look up account", "get events", "query blockchain", "flow accounts get", "flow scripts execute", "flow events get", "flow blocks get", "findapi", "transfer history", "tax report", "NFT holdings", "what's on chain", "read contract state".
  DO NOT TRIGGER when: writing or debugging Cadence contracts (use cadence-lang), building token contracts (use cadence-tokens), composing DeFi transactions (use cadence-defi-actions), setting up flow.json or deploying (use flow-project-setup), generating new code (use cadence-scaffold).
---

# Flow Blockchain Queries

Read any on-chain data from Flow using the CLI or historical API.

## Quick Decision

- **Current state** (balance, keys, contracts, blocks, events, tx status) → `flow-cli`
- **Historical data** (transfer history, NFT holdings, tax reports, node rewards) → `findapi`
- **Custom queries** → `flow scripts execute` with a Cadence script

## Default Network

Infer from context: `--network mainnet` (default), `--network testnet`, `--network emulator`.

## Navigation Map

| Task | Reference |
|------|-----------|
| flow-cli commands: accounts, blocks, events, transactions, collections, Cadence scripts | [query-blockchain.md](references/query-blockchain.md) |
| findapi commands: transfer history, NFT holdings, tax reports, nodes, contracts, EVM | [query-findapi.md](references/query-findapi.md) |
