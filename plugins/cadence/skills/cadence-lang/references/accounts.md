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
let exists = account.storage.check<@MyResource>(/storage/myResource)
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
prepare(signer: auth(StorageCapabilities, Capabilities) &Account) {
    let controller = signer.capabilities.storage
        .issue<&Resource>(/storage/resource)
    controller.setTag("Public read-only access")
    signer.capabilities.publish(controller.capability, at: /public/resource)
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

// Claimer
let cap = signer.inbox.claim<&MyResource>(name: "myResource", provider: providerAddress)
    ?? panic("Capability not found in inbox")

// Unpublish
signer.inbox.unpublish<&MyResource>(name: name, recipient: recipientAddress)
```

## Account Entitlements

### Fine-Grained
```cadence
auth(SaveValue) &Account              // Save to storage
auth(LoadValue) &Account              // Load from storage
auth(BorrowValue) &Account            // Borrow reference
auth(CopyValue) &Account              // Copy struct values
auth(StorageCapabilities) &Account    // Issue/get storage cap controllers
auth(AccountCapabilities) &Account    // Issue/get account cap controllers
auth(AddKey) &Account                 // Add key
auth(RevokeKey) &Account              // Revoke key
auth(AddContract) &Account            // Deploy contract
auth(UpdateContract) &Account         // Update contract
auth(RemoveContract) &Account         // Remove contract
auth(PublishInboxCapability) &Account  // Publish to inbox
auth(ClaimInboxCapability) &Account    // Claim from inbox
```

### Coarse-Grained
```cadence
auth(Storage) &Account       // All storage ops
auth(Capabilities) &Account  // All capability ops
auth(Keys) &Account          // All key ops
auth(Contracts) &Account     // All contract ops
auth(Inbox) &Account         // All inbox ops
```

### Common Combinations
```cadence
auth(BorrowValue) &Account                                    // Read-only
auth(BorrowValue, SaveValue) &Account                          // Read + write
auth(BorrowValue, SaveValue, StorageCapabilities) &Account     // + cap issuance
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
