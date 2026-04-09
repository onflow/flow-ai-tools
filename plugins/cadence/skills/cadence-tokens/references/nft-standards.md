# NFT Development Standards

## Core Interface Conformance

### Contract Level
```cadence
access(all) contract MyNFT: NonFungibleToken {
```

### NFT Resource
```cadence
access(all) resource NFT: NonFungibleToken.NFT {
```

### Collection Resource
```cadence
access(all) resource Collection: NonFungibleToken.Collection {
```

## Required Standard Functions

### Contract Level
- `createEmptyCollection(): @{NonFungibleToken.Collection}`
- `getContractViews(resourceType: Type?): [Type]`
- `resolveContractView(resourceType: Type?, viewType: Type): AnyStruct?`

### NFT Resource
- `getViews(): [Type]` — Return supported MetadataViews
- `resolveView(_ view: Type): AnyStruct?` — Resolve specific metadata views

### Collection Resource
- `deposit(token: @{NonFungibleToken.NFT})`
- `withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT}` with proper entitlements
- `getIDs(): [UInt64]`
- `borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}?`
- `getSupportedNFTTypes(): {Type: Bool}`
- `isSupportedNFTType(type: Type): Bool`

## MetadataViews Integration

### Essential Views (always implement)
- `MetadataViews.Display` — Name, description, thumbnail
- `MetadataViews.Serial` — Unique identifier
- `MetadataViews.NFTCollectionData` — Collection metadata
- `MetadataViews.NFTCollectionDisplay` — Collection display info

### Advanced Views (when applicable)
- `MetadataViews.Editions` — For limited editions
- `MetadataViews.Traits` — For attribute-based NFTs
- `MetadataViews.Royalties` — For creator royalties

## Standard Path Conventions
```cadence
access(all) let CollectionStoragePath: StoragePath
access(all) let CollectionPublicPath: PublicPath
// Use versioned paths: /storage/MyNFTCollectionV1
```
Initialize paths in `init()`. Ensure transactions use the contract's path variables.

## Resource Type Declarations
```cadence
// Storage Dictionary
@{UInt64: {NonFungibleToken.NFT}}

// Function Parameters
token: @{NonFungibleToken.NFT}

// References
&{NonFungibleToken.NFT}?
```

## File Structure
Each `.cdc` file MUST contain exactly ONE top-level contract declaration. Supporting structs, resources, and interfaces must be nested within the contract.

## Secure Capability Management

Admin and minting resources must NEVER be publicly accessible. Only existing admins can create new minters.

```cadence
access(all) contract MyAsset {
    access(all) entitlement Mint

    access(all) resource Admin {
        access(Mint) fun mintNFT(): @NonFungibleToken.NFT { /* ... */ }
        access(Mint) fun createMinter(): @Minter { return <- create Minter() }
    }

    access(all) resource Minter {
        access(Mint) fun mintNFT(): @NonFungibleToken.NFT { /* ... */ }
    }

    init() {
        // Admin stored privately — NO public capability
        self.account.storage.save(<- create Admin(), to: /storage/myAssetAdmin)
        // No public minter capability — minting is admin-only
    }
}
```

**Anti-pattern** — never publish minting capabilities publicly:
```cadence
// ❌ INSECURE: Anyone can borrow and mint unlimited NFTs
self.account.capabilities.publish(
    self.account.capabilities.storage.issue<&Minter>(/storage/minter),
    at: /public/minter
)
```

## Standardized Event Emission
```cadence
access(all) event Minted(nftID: UInt64, recipient: Address)
access(all) event Transferred(nftID: UInt64, from: Address, to: Address)
```
Lean towards oversharing metadata. Include all key identifiers (nftID, itemID, recipient, etc.).

## Explicit Resource Handling
Every resource (`@`) must have a clear destination: moved to storage, returned, or explicitly destroyed. Incorrect handling leads to resource loss or inconsistent states.

> **See also:** `cadence-lang` skill → `resources.md` for resource rules, `access-control.md` for visibility rules, `entitlements.md` for entitlement patterns on token operations.
