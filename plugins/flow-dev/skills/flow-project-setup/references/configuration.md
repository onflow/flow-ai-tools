# Flow Configuration

## Project Structure
```
my-project/
├── flow.json
├── emulator-account.pkey
├── cadence/
│   ├── contracts/
│   ├── scripts/
│   ├── transactions/
│   └── tests/
└── src/config/fcl-config.js
```

## flow.json Core Sections

```json
{
  "networks": {},
  "accounts": {},
  "contracts": {},
  "dependencies": {},
  "deployments": {}
}
```

### Networks
```json
"networks": {
  "emulator": "127.0.0.1:3569",
  "testnet": "access.devnet.nodes.onflow.org:9000",
  "mainnet": "access.mainnet.nodes.onflow.org:9000"
}
```

### Accounts
```json
"accounts": {
  "emulator-account": {
    "address": "f8d6e0586b0a20c7",
    "key": { "type": "file", "location": "emulator-account.pkey" }
  },
  "testnet-deployer": {
    "address": "544ad93e4effc077",
    "key": { "type": "file", "location": "testnet-deployer.pkey" }
  }
}
```
For production, use file-based key storage (`.pkey` files outside the repo) or a secrets manager. Environment variable substitution (`${ENV_VAR}`) is not officially supported in `flow.json` key fields — use file-based keys with a `.gitignore` exclusion instead.

### Contracts
```json
"contracts": {
  "MyContract": {
    "source": "./cadence/contracts/MyContract.cdc",
    "aliases": {
      "emulator": "f8d6e0586b0a20c7",
      "testnet": "544ad93e4effc077"
    }
  }
}
```

### Dependencies (Core Flow Contracts)
```json
"dependencies": {
  "NonFungibleToken": {
    "source": "mainnet://1d7e57aa55817448.NonFungibleToken",
    "hash": "<run `flow dependencies install` to auto-populate the current hash>",
    "aliases": {
      "emulator": "f8d6e0586b0a20c7",
      "testnet": "631e88ae7f1d7c20",
      "mainnet": "1d7e57aa55817448"
    }
  }
}
```

### Deployments
```json
"deployments": {
  "emulator": { "emulator-account": ["MyContract"] },
  "testnet": { "testnet-deployer": ["MyContract"] }
}
```

## FCL Configuration

```typescript
import { config } from '@onflow/fcl';
import flowJSON from '../../flow.json';

const networkConfigs = {
  emulator: {
    'flow.network': 'emulator',
    'accessNode.api': 'http://127.0.0.1:8888',
    'discovery.wallet': 'http://localhost:8701/fcl/authn'
  },
  testnet: {
    'flow.network': 'testnet',
    'accessNode.api': 'https://rest-testnet.onflow.org',
    'discovery.wallet': 'https://fcl-discovery.onflow.org/testnet/authn'
  },
  mainnet: {
    'flow.network': 'mainnet',
    'accessNode.api': 'https://rest-mainnet.onflow.org',
    'discovery.wallet': 'https://fcl-discovery.onflow.org/authn'
  }
};

const network = process.env.NEXT_PUBLIC_FLOW_NETWORK || 'testnet';
config({ ...networkConfigs[network], 'app.detail.title': 'My App' }).load({ flowJSON });
```

### React Integration
When using `@onflow/react-sdk`, pass config directly to `FlowProvider` instead of a separate FCL config file:

```tsx
import { FlowProvider } from '@onflow/react-sdk';
import flowJSON from '../flow.json';

function App() {
  return (
    <FlowProvider
      config={{
        accessNodeUrl: 'https://rest-testnet.onflow.org',
        flowNetwork: 'testnet',
        appDetailTitle: 'My App',
      }}
      flowJson={flowJSON}
    >
      <YourAppComponents />
    </FlowProvider>
  );
}
```

> **Note:** The raw FCL config pattern above (`config(...).load({ flowJSON })`) applies to non-React apps or raw FCL usage. Do not mix both approaches — `FlowProvider` handles FCL configuration internally via its props.

## Standard Contract Addresses

**Testnet**: NonFungibleToken `0x631e88ae7f1d7c20`, FungibleToken `0x9a0766d93b6608b7`, MetadataViews `0x631e88ae7f1d7c20`, FlowToken `0x7e60df042a9c0868`

**Mainnet**: NonFungibleToken `0x1d7e57aa55817448`, FungibleToken `0xf233dcee88fe0abe`, MetadataViews `0x1d7e57aa55817448`, FlowToken `0x1654653399040a61`

## CLI Commands
```bash
flow config add account / contract / deployment
flow config remove account my-account
flow dependencies install / discover / list
```

## Environment Variables
```bash
# .env.development
NEXT_PUBLIC_FLOW_NETWORK=emulator
# .env.staging
NEXT_PUBLIC_FLOW_NETWORK=testnet
# .env.production
NEXT_PUBLIC_FLOW_NETWORK=mainnet
FLOW_MAINNET_PRIVATE_KEY=<secure-key>
```

## Common Issues

| Issue | Solution |
|-------|----------|
| "Account not found" | Verify account name in flow.json is correct |
| "Contract not found" | Register contract in flow.json first |
| "Address mismatch" | Check aliases match between flow.json, imports, FCL |
| "Failed to resolve import" | Add alias for target network in flow.json |
| "Insufficient FLOW" | Fund deploying account |

## Best Practices
- Never commit private keys — use file-based keys + `.gitignore`
- Use environment variables for production
- Validate config before deployment
- Synchronize FCL config with flow.json
- Use `flow dependencies install` for standard contracts
