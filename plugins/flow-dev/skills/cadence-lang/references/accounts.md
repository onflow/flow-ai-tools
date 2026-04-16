# Cadence Account Rules

Accounts are multi-faceted entities managing storage, capabilities, keys, contracts, and inbox.

## Account Components
```cadence
account.address        // Account address
account.storage        // Storage management
account.capabilities   // Capability management
account.keys           // Key management
account.contracts      // Contract management
account.inbox          // Inbox for capability bootstrapping
```

## Account Storage

### Storage Operations
```cadence
// Save resource
signer.storage.save(<-resource, to: /storage/myResource)

// Load resource (removes from storage)
let resource <- signer.storage.load<@MyResource>(from: /storage/myResource)
    ?? panic("Resource not found at /storage/myResource")

// Borrow reference (preferred — resource stays in storage)
let ref = signer.storage.borrow<&MyResource>(from: /storage/myResource)
    ?? panic("Could not borrow reference from /storage/myResource")

// Copy struct value
let data = signer.storage.copy<MyStruct>(from: /storage/myData)

// Check existence
let exists = account.storage.check<@MyResource>(from: /storage/myResource)
```

### Required Entitlements
```cadence
auth(SaveValue) &Account      // save()
auth(LoadValue) &Account      // load()
auth(BorrowValue) &Account    // borrow()
auth(CopyValue) &Account      // copy()
```

## Capabilities

### Issue and Publish
```cadence
prepare(signer: auth(IssueStorageCapabilityController, PublishCapability) &Account) {
    // issue() returns Capability<T> directly — not StorageCapabilityController
    let cap = signer.capabilities.storage
        .issue<&Resource>(/storage/resource)
    signer.capabilities.publish(cap, at: /public/resource)
}
```

### Get and Borrow
```cadence
let cap = getAccount(address).capabilities.get<&{PublicInterface}>(/public/resource)
if let ref = cap.borrow() {
    ref.publicFunction()
}
```

### Controllers
```cadence
// Get controllers for a path
let controllers = account.capabilities.storage.getControllers(forPath: /storage/resource)

// Delete capability (call delete on the controller directly)
controller.delete()

// Retarget to new path (storage caps only)
controller.retarget(/storage/newPath)
```

### Unpublish
```cadence
signer.capabilities.unpublish(/public/resource)
```

## Account Keys

```cadence
// Add key
let key = PublicKey(publicKey: publicKey.decodeHex(), signatureAlgorithm: SignatureAlgorithm.ECDSA_P256)
signer.keys.add(publicKey: key, hashAlgorithm: hashAlgorithm, weight: weight)

// Revoke key
signer.keys.revoke(keyIndex: keyIndex)

// Get key
let key = account.keys.get(keyIndex: 0)
```

## Account Contracts

```cadence
signer.contracts.add(name: name, code: code.utf8)       // Deploy
signer.contracts.update(name: name, code: newCode.utf8)  // Update
signer.contracts.remove(name: name)                       // Remove
let names = account.contracts.names                       // List
```

## Account Inbox

Cross-account capability bootstrapping:

```cadence
// Publisher
signer.inbox.publish(controller.capability, name: "myResource", recipient: recipientAddress)

// Claimer — first arg has no external label (signature uses _)
let cap = signer.inbox.claim<&MyResource>("myResource", provider: providerAddress)
    ?? panic("Capability not found in inbox")

// Unpublish
signer.inbox.unpublish<&MyResource>(name)
```

## Account Entitlements

Capability entitlements have **three tiers** — prefer the most specific that covers your needs.

### Fine-Grained (prefer for Principle of Least Authority)
```cadence
// Storage
auth(SaveValue) &Account              // Save to storage
auth(LoadValue) &Account              // Load from storage
auth(BorrowValue) &Account            // Borrow reference
auth(CopyValue) &Account              // Copy struct values

// Capabilities — most specific (sub-entitlements of StorageCapabilities/AccountCapabilities)
auth(IssueStorageCapabilityController) &Account  // Issue new storage capability
auth(GetStorageCapabilityController) &Account    // Get/query storage cap controllers
auth(IssueAccountCapabilityController) &Account  // Issue new account capability
auth(GetAccountCapabilityController) &Account    // Get/query account cap controllers
auth(PublishCapability) &Account                 // Publish capability to public area
auth(UnpublishCapability) &Account               // Unpublish capability from public area

// Keys
auth(AddKey) &Account                 // Add key
auth(RevokeKey) &Account              // Revoke key

// Contracts
auth(AddContract) &Account            // Deploy contract
auth(UpdateContract) &Account         // Update contract
auth(RemoveContract) &Account         // Remove contract

// Inbox
auth(PublishInboxCapability) &Account    // Publish to inbox
auth(ClaimInboxCapability) &Account     // Claim from inbox
auth(UnpublishInboxCapability) &Account // Unpublish from inbox
```

### Intermediate (subsumes fine-grained within the category)
```cadence
auth(StorageCapabilities) &Account    // Issue + Get storage cap controllers
auth(AccountCapabilities) &Account    // Issue + Get account cap controllers
```

### Coarse-Grained (use sparingly)
```cadence
auth(Storage) &Account       // All storage ops
auth(Capabilities) &Account  // All capability ops (subsumes StorageCapabilities + AccountCapabilities)
auth(Keys) &Account          // All key ops
auth(Contracts) &Account     // All contract ops
auth(Inbox) &Account         // All inbox ops
```

### Common Combinations
```cadence
auth(BorrowValue) &Account                                                     // Read-only
auth(BorrowValue, SaveValue) &Account                                          // Read + write
auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability) &Account  // + cap issuance
```

## Creating New Accounts
```cadence
let newAccount = Account(payer: payer)
```

## Best Practices

1. **Minimal entitlements** — request only what you need in transactions
2. **Use capabilities for delegation** — never pass `auth(...) &Account` to functions
3. **Check storage before saving** — verify path is empty
4. **Clean up storage** — remove unused resources
5. **Tag capabilities** — use descriptive tags for management
