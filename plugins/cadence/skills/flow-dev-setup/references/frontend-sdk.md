# Frontend SDK Setup

Flow provides two main options for frontend integration: the **React SDK** (recommended for React apps) and **FCL** (Flow Client Library, for any JavaScript framework).

**Only needed for frontend development.** If you're only writing Cadence contracts, skip this.

## Prerequisites

- Node.js installed
- A Flow project with `flow.json` (see [flow-cli.md](flow-cli.md))

## Option 1: React SDK (Recommended for React)

### Install
```bash
npm install @onflow/react-sdk
```

### Configure
```typescript
import { FlowProvider } from '@onflow/react-sdk';
import flowJson from '../flow.json';

const network = process.env.NEXT_PUBLIC_FLOW_NETWORK || 'testnet';

function App() {
  return (
    <FlowProvider
      config={{
        accessNodeUrl: networkConfigs[network].accessNodeUrl,
        flowNetwork: network,
        discoveryWallet: networkConfigs[network].discoveryWallet,
        appDetailTitle: 'My App',
      }}
      flowJson={flowJson}
    >
      <YourAppComponents />
    </FlowProvider>
  );
}
```

## Option 2: FCL (Any Framework)

### Install
```bash
npm install @onflow/fcl
```

Requires `@onflow/fcl` >= 1.0.0.

### Configure
```typescript
import { config } from '@onflow/fcl';
import flowJSON from '../flow.json';

const networkConfigs = {
  emulator: {
    'flow.network': 'emulator',
    'accessNode.api': 'http://127.0.0.1:8888',
    'discovery.wallet': 'http://localhost:8701/fcl/authn',
  },
  testnet: {
    'flow.network': 'testnet',
    'accessNode.api': 'https://rest-testnet.onflow.org',
    'discovery.wallet': 'https://fcl-discovery.onflow.org/testnet/authn',
  },
  mainnet: {
    'flow.network': 'mainnet',
    'accessNode.api': 'https://rest-mainnet.onflow.org',
    'discovery.wallet': 'https://fcl-discovery.onflow.org/authn',
  },
};

const network = process.env.NEXT_PUBLIC_FLOW_NETWORK || 'testnet';
config({ ...networkConfigs[network], 'app.detail.title': 'My App' }).load({ flowJSON });
```

## Network Reference

| Network | Access Node (REST) | Wallet Discovery |
|---------|-------------------|------------------|
| Emulator | `http://127.0.0.1:8888` | `http://localhost:8701/fcl/authn` |
| Testnet | `https://rest-testnet.onflow.org` | `https://fcl-discovery.onflow.org/testnet/authn` |
| Mainnet | `https://rest-mainnet.onflow.org` | `https://fcl-discovery.onflow.org/authn` |

## Environment Variables

```bash
# .env.development
NEXT_PUBLIC_FLOW_NETWORK=emulator

# .env.staging
NEXT_PUBLIC_FLOW_NETWORK=testnet

# .env.production
NEXT_PUBLIC_FLOW_NETWORK=mainnet
```

## Local Development

For local frontend testing against the emulator, you also need the **dev wallet** — see [dev-wallet.md](dev-wallet.md).

## Documentation

- React SDK: https://developers.flow.com/tools/clients/fcl-js
- FCL reference: https://developers.flow.com/tools/clients/fcl-js
