# Cadence Import Rules

## Three Import Methods

### Method 1: String Imports (Recommended)
Use string literals with automatic address resolution via `flow.json`:
```cadence
import "FungibleToken"
import "FlowToken"
import "MyContract"
```
- Network-agnostic code — no changes when deploying to different networks
- Flow CLI reads `flow.json` to resolve contract names to addresses

### Method 2: Address Imports (Playground Only)
```cadence
import 0x1234567890abcdef
```
- Not portable across networks, imports ALL public declarations

### Method 3: Selective Imports (from file path)
```cadence
import MyContract from "./contracts/MyContract.cdc"
```
> **Note:** `import X from 0xADDRESS` is valid syntax but not recommended. Prefer string imports (`import "X"`) for portable, network-agnostic code.

## Rules

### Rule 1: Default to String Imports
```cadence
// ✅ CORRECT
import "FungibleToken"

// ❌ AVOID (unless in Playground)
import 0x1234567890abcdef
```

### Rule 2: Standard Import Order
1. Core Flow contracts (alphabetical)
2. Third-party protocol contracts (alphabetical)
3. Project contracts (alphabetical)

```cadence
// Core Flow
import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"

// Third-party
import "DeFiActions"
import "SwapConnectors"

// Project
import "MyContract"
```

### Rule 3: One Import Per Line
```cadence
// ✅ CORRECT
import "FungibleToken"
import "FlowToken"

// ❌ WRONG
import "FungibleToken", "FlowToken"
```

### Rule 4: No Unused Imports
Only import what you actually use in the file.

## Import Patterns by File Type

### Contract
```cadence
import "FungibleToken"
import "NonFungibleToken"

access(all) contract MyNFTContract { }
```

### Transaction
```cadence
import "FungibleToken"
import "MyContract"

transaction(amount: UFix64) {
    prepare(signer: auth(BorrowValue) &Account) { }
}
```

### Script
```cadence
import "FungibleToken"

access(all) fun main(address: Address): UFix64 { }
```

## flow.json Configuration

```json
{
  "contracts": {
    "FungibleToken": {
      "source": "./cadence/contracts/FungibleToken.cdc",
      "aliases": {
        "emulator": "0xee82856bf20e2aa6",
        "testnet": "0x9a0766d93b6608b7",
        "mainnet": "0xf233dcee88fe0abe"
      }
    },
    "MyContract": {
      "source": "./cadence/contracts/MyContract.cdc",
      "aliases": {
        "emulator": "0xf8d6e0586b0a20c7"
      }
    }
  },
  "networks": {
    "emulator": "127.0.0.1:3569",
    "testnet": "access.devnet.nodes.onflow.org:9000",
    "mainnet": "access.mainnet.nodes.onflow.org:9000"
  }
}
```

## Common Import Errors

**"cannot find contract in imported address"**
- Verify `flow.json` has correct address for the network
- Ensure contract is deployed at specified address

**"cyclic import"**
- Extract shared interfaces into separate contracts
- Use interface imports instead of concrete types

**"ambiguous use of imported declaration"**
- Use fully qualified names: `ContractA.SharedType()` vs `ContractB.SharedType()`

## Migration: Address to String Imports

1. Identify contracts at each address
2. Add contracts to `flow.json` with aliases
3. Replace address imports with string imports
4. Test on emulator, then deploy
