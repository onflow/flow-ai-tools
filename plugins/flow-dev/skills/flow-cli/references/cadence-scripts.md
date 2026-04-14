# Cadence Script Recipes

Ready-to-use scripts for common Flow blockchain queries. Execute with:
```bash
flow scripts execute <script-file> [args] --network mainnet
```

---

## Token Queries

### Get FLOW Balance
```cadence
import "FungibleToken"
import "FlowToken"

access(all) fun main(address: Address): UFix64 {
    let account = getAccount(address)
    let vaultRef = account.capabilities
        .borrow<&{FungibleToken.Balance}>(/public/flowTokenBalance)
        ?? panic("Could not borrow FlowToken balance capability from \(address)")
    return vaultRef.balance
}
```

### Get FLOW Balance (Multiple Accounts)
```cadence
import "FungibleToken"
import "FlowToken"

access(all) fun main(addresses: [Address]): {Address: UFix64} {
    let balances: {Address: UFix64} = {}
    for address in addresses {
        let account = getAccount(address)
        if let vaultRef = account.capabilities
            .borrow<&{FungibleToken.Balance}>(/public/flowTokenBalance) {
            balances[address] = vaultRef.balance
        } else {
            balances[address] = 0.0
        }
    }
    return balances
}
```

### Get FT Total Supply
```cadence
import "FlowToken"

access(all) fun main(): UFix64 {
    return FlowToken.totalSupply
}
```

### Check FT Receiver Capability
```cadence
import "FungibleToken"

access(all) fun main(address: Address, publicPath: PublicPath): Bool {
    let account = getAccount(address)
    return account.capabilities
        .borrow<&{FungibleToken.Receiver}>(publicPath) != nil
}
```

---

## Account & Storage Queries

### Get Account Keys
```cadence
access(all) fun main(address: Address): [{String: AnyStruct}] {
    let account = getAccount(address)
    var keys: [{String: AnyStruct}] = []
    var i = 0
    while true {
        if let key = account.keys.get(keyIndex: i) {
            keys.append({
                "index": i,
                "weight": key.weight,
                "hashAlgorithm": key.hashAlgorithm.rawValue,
                "signatureAlgorithm": key.signatureAlgorithm.rawValue,
                "isRevoked": key.isRevoked
            })
            i = i + 1
        } else {
            break
        }
    }
    return keys
}
```

### Get Deployed Contract Names
```cadence
access(all) fun main(address: Address): [String] {
    return getAccount(address).contracts.names
}
```

### Check Storage Capacity
```cadence
import "FlowStorageFees"

access(all) fun main(address: Address): {String: UFix64} {
    let account = getAccount(address)
    let used = account.storage.used
    let capacity = account.storage.capacity
    return {
        "used": UFix64(used),
        "capacity": UFix64(capacity),
        "available": UFix64(capacity) - UFix64(used)
    }
}
```

---

## Epoch & Protocol Queries

### Get Current Epoch Counter
```cadence
import "FlowEpoch"

access(all) fun main(): UInt64 {
    return FlowEpoch.currentEpochCounter
}
```

### Get Epoch Metadata
```cadence
import "FlowEpoch"

access(all) fun main(epochCounter: UInt64): FlowEpoch.EpochMetadata? {
    return FlowEpoch.getEpochMetadata(epochCounter)
}
```

### Get Current Block Info
```cadence
access(all) fun main(): {String: AnyStruct} {
    let block = getCurrentBlock()
    return {
        "height": block.height,
        "id": block.id,
        "timestamp": block.timestamp
    }
}
```

---

## Staking Queries

### Get Node Info
```cadence
import "FlowIDTableStaking"

access(all) fun main(nodeID: String): FlowIDTableStaking.NodeInfo? {
    return FlowIDTableStaking.getNodeInfo(nodeID: nodeID)
}
```

### Get All Node IDs
```cadence
import "FlowIDTableStaking"

access(all) fun main(): [String] {
    return FlowIDTableStaking.getNodeIDs()
}
```

### Get Delegator Info
```cadence
import "FlowIDTableStaking"

access(all) fun main(nodeID: String, delegatorID: UInt32): FlowIDTableStaking.DelegatorInfo? {
    return FlowIDTableStaking.getDelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
}
```

### Get Total Staked FLOW
```cadence
import "FlowIDTableStaking"

access(all) fun main(): UFix64 {
    return FlowIDTableStaking.getTotalStaked()
}
```

### Get Staking Rewards
```cadence
import "FlowIDTableStaking"

access(all) fun main(): UFix64 {
    return FlowIDTableStaking.getEpochTokenPayout()
}
```

---

## NFT Collection Queries

### Get NFT IDs in Collection
```cadence
import "NonFungibleToken"

access(all) fun main(address: Address, collectionPublicPath: PublicPath): [UInt64] {
    let account = getAccount(address)
    let collection = account.capabilities
        .borrow<&{NonFungibleToken.Collection}>(collectionPublicPath)
        ?? panic("Could not borrow NFT collection from \(address) at \(collectionPublicPath)")
    return collection.getIDs()
}
```

### Get NFT Count
```cadence
import "NonFungibleToken"

access(all) fun main(address: Address, collectionPublicPath: PublicPath): Int {
    let account = getAccount(address)
    if let collection = account.capabilities
        .borrow<&{NonFungibleToken.Collection}>(collectionPublicPath) {
        return collection.getIDs().length
    }
    return 0
}
```

### Check If Collection Exists
```cadence
import "NonFungibleToken"

access(all) fun main(address: Address, collectionPublicPath: PublicPath): Bool {
    let account = getAccount(address)
    return account.capabilities
        .borrow<&{NonFungibleToken.Collection}>(collectionPublicPath) != nil
}
```

### Get NFT Display Metadata
```cadence
import "NonFungibleToken"
import "MetadataViews"

access(all) fun main(
    address: Address,
    collectionPublicPath: PublicPath,
    nftID: UInt64
): MetadataViews.Display? {
    let account = getAccount(address)
    let collection = account.capabilities
        .borrow<&{NonFungibleToken.Collection}>(collectionPublicPath)
        ?? panic("Could not borrow collection")
    let nft = collection.borrowNFT(nftID) ?? panic("NFT \(nftID) not found")
    return nft.resolveView(Type<MetadataViews.Display>()) as? MetadataViews.Display
}
```

---

## EVM & Cross-VM Queries

### Get EVM Address for Flow Address
```cadence
import "EVM"

access(all) fun main(address: Address): String? {
    let account = getAccount(address)
    if let coa = account.capabilities
        .borrow<&EVM.CadenceOwnedAccount>(/public/evm) {
        return coa.address().toString()
    }
    return nil
}
```

### Get COA EVM Balance
```cadence
import "EVM"

// Returns EVM balance (in attoFLOW) for a Flow account's COA, if it has one
access(all) fun main(flowAddress: Address): UInt? {
    if let coa = getAccount(flowAddress).capabilities
        .borrow<&EVM.CadenceOwnedAccount>(/public/evm) {
        return coa.address().balance().inAttoFLOW()
    }
    return nil
}
```

> **See also:** `query-blockchain.md` for CLI commands to execute these scripts.
