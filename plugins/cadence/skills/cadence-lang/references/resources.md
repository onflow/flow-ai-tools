# Cadence Resource Rules

Resources follow **linear typing**: they exist in exactly one location and must be explicitly handled.

## Three Fundamental Rules

### Rule 1: Singular Existence
Resources can only exist in ONE location at a time.
```cadence
let nft <- collection.withdraw(id: 1)
otherCollection.deposit(token: <-nft)  // Now in new location
```

### Rule 2: Mandatory Handling
Resources must be explicitly moved or destroyed.
```cadence
let vault <- createVault()
destroy vault  // Or save to storage
```

### Rule 3: Explicit Syntax
Use `@` for types and `<-` for operations.
```cadence
let vault: @Vault <- createVault()
account.storage.save(<-vault, to: /storage/vault)
```

## Resource Creation
```cadence
let nft <- create NFT(id: 1, metadata: {})

access(all) fun mintNFT(id: UInt64): @NFT {
    return <- create NFT(id: id, metadata: {})
}
```

## The Move Operator (`<-`)

Use `<-` for: assignment, function arguments, returns, storage operations, and collection operations.

```cadence
// Assignment
let vault <- createVault()

// Function argument
deposit(vault: <-myVault)

// Storage
account.storage.save(<-vault, to: /storage/vault)
let vault <- account.storage.load<@Vault>(from: /storage/vault)

// Arrays/Dictionaries
vaults.append(<-vault)
nfts[id] <-! nft           // Force-insert
let old <- nfts[id] <- nft  // Swap
```

**After move, variable is invalid:**
```cadence
let nft <- create NFT(id: 1)
let id = nft.id              // Read BEFORE moving
collection.deposit(<-nft)
log(id)                       // Safe: using copied value
// log(nft.id)               // COMPILE ERROR: nft moved
```

## Resource Destruction

### Explicit Destruction
```cadence
destroy vault
```

### Burner Contract (for meaningful resources)
Ensures burn callbacks execute (events, supply reduction):
```cadence
import "Burner"
Burner.burn(<-vault)
```

### Use `defer` for Panic-Safe Cleanup
`defer` runs on ALL exit paths including panics — preferred for DeFi/vault handling:
```cadence
fun process(vault: @{FungibleToken.Vault}) {
    defer { destroy vault }  // Runs even if panic occurs below
    assert(vault.balance == 0.0, message: "Transfer incomplete")
    doWork()
}
```

### Nested Resources
Parent destruction automatically destroys nested resources.

## Resource Collections

### Dictionary Operations
```cadence
access(all) resource NFTCollection {
    access(self) var nfts: @{UInt64: NFT}

    access(all) fun deposit(nft: @NFT) {
        let id = nft.id
        let old <- self.nfts[id] <- nft
        destroy old
    }

    access(Withdraw) fun withdraw(id: UInt64): @NFT {
        let nft <- self.nfts.remove(key: id)
            ?? panic("NFT with ID \(id) not found in collection")
        return <-nft
    }

    // Force-insert (panics if key exists)
    access(all) fun safeDeposit(nft: @NFT) {
        self.nfts[nft.id] <-! nft
    }
}
```

### Array Operations
```cadence
self.vaults.append(<-vault)
let vault <- self.vaults.remove(at: index)
```

## Resource Scope and Validity

**All code paths must handle resources:**
```cadence
// ✅ CORRECT
fun processVault(vault: @Vault, save: Bool) {
    if save {
        account.storage.save(<-vault, to: /storage/vault)
    } else {
        destroy vault
    }
}

// ❌ WRONG: else path doesn't handle vault
fun processVault(vault: @Vault, save: Bool) {
    if save {
        account.storage.save(<-vault, to: /storage/vault)
    }
    // COMPILE ERROR
}
```

**Destroy before reassigning:**
```cadence
var vault: @Vault <- create Vault(balance: 0.0)
let old <- vault <- create Vault(balance: 100.0)
destroy old
```

## Built-in Fields

- `uuid`: Every resource gets a unique identifier automatically
- `owner`: Resources in storage know which account owns them (`self.owner?.address`)

## Resource References

References do NOT use the move operator — original resource stays valid:
```cadence
let vaultRef = &vault as &Vault
log(vaultRef.balance)  // Reference
log(vault.balance)     // Original still valid
```

## Common Patterns

### Optional Resource Handling
```cadence
if let nft <- collection.maybeWithdraw(id: 1) {
    otherCollection.deposit(nft: <-nft)
}
```

### Batch Operations
```cadence
access(all) fun depositBatch(nfts: @[NFT]) {
    while nfts.length > 0 {
        let nft <- nfts.removeFirst()
        self.deposit(nft: <-nft)
    }
    destroy nfts
}
```

### Resource Transformation
```cadence
access(all) fun upgrade(old: @OldNFT): @NewNFT {
    let id = old.id   // Copy data before destroying
    destroy old
    return <- create NewNFT(id: id)
}
```
