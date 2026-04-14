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

### Minimal Setup
```typescript
import { FlowProvider } from '@onflow/react-sdk';
import flowJson from '../flow.json';

function App() {
  return (
    <FlowProvider
      config={{
        accessNodeUrl: 'https://rest-testnet.onflow.org',
        flowNetwork: 'testnet',
        appDetailTitle: 'My App',
      }}
      flowJson={flowJson}
    >
      <YourAppComponents />
    </FlowProvider>
  );
}
```

Common access node URLs:
- Emulator: `http://127.0.0.1:8888`
- Testnet: `https://rest-testnet.onflow.org`
- Mainnet: `https://rest-mainnet.onflow.org`

For full React SDK documentation including hooks and components, see the `flow-react-sdk` skill.

## Option 2: FCL (Any Framework)

### Install
```bash
npm install @onflow/fcl
```

### Minimal Setup
```typescript
import { config } from '@onflow/fcl';
import flowJSON from '../flow.json';

config({
  'flow.network': 'testnet',
  'accessNode.api': 'https://rest-testnet.onflow.org',
  'discovery.wallet': 'https://fcl-discovery.onflow.org/testnet/authn',
  'app.detail.title': 'My App',
}).load({ flowJSON });
```

## Local Development

For local frontend testing against the emulator, you also need the **dev wallet** — see [dev-wallet.md](dev-wallet.md).

## Documentation

- React SDK: https://developers.flow.com/tools/clients/react-sdk
- FCL reference: https://developers.flow.com/tools/clients/fcl-js
