---
name: cadence-tokens
description: |
  Guide for developing NFT and Fungible Token contracts on the Flow blockchain using Cadence. Covers NonFungibleToken and FungibleToken interface conformance, MetadataViews integration for marketplace compatibility, collection patterns, minting, standard paths, event emission, and modular NFT architectures for complex traits and evolution.
  TRIGGER when: building NFT contracts, FT token contracts, implementing NonFungibleToken or FungibleToken interfaces, working with MetadataViews, creating collections, minting tokens, "create an NFT", "build a token contract", "mint NFT", "NFT collection", "fungible token vault", "royalties", "MetadataViews.Display", "NonFungibleToken.Collection", "token standards", "FungibleToken.Vault".
  DO NOT TRIGGER when: asking about general Cadence syntax or patterns (use cadence-lang), composing DeFi transactions (use cadence-defi-actions), setting up flow.json or deploying (use flow-project-setup), auditing code (use cadence-audit).
---

# Cadence Token Development

Build NFT and FT contracts that conform to Flow's standard interfaces for marketplace and wallet compatibility.

## Quick Start

1. Import standard contracts: `NonFungibleToken`, `FungibleToken`, `MetadataViews`
2. Implement required interfaces on contract, resource, and collection
3. Add MetadataViews for marketplace compatibility
4. Set up standard storage/public paths
5. Emit events for all significant actions

## Navigation Map

| Task | Reference |
|------|-----------|
| NFT interface conformance, required functions, MetadataViews, paths, events | [nft-standards.md](references/nft-standards.md) |
| Modular NFT design, trait systems, FT patterns, advanced architectures | [token-patterns.md](references/token-patterns.md) |

## Companion Skills

- **`cadence-lang`** — Always consult for access control, entitlements, resource handling, and security patterns when building token contracts. Token code must follow all Cadence security rules.
- **`cadence-scaffold`** — Use to generate a token contract from scratch with proper structure.
- **`cadence-audit`** — Use to review token contracts for security vulnerabilities before deployment.
- **`flow-project-setup`** — Use for deploying token contracts and configuring flow.json dependencies.
