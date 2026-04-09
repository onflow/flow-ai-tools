# Flow Dev Wallet

The Flow Dev Wallet is a mock FCL-compatible wallet for local frontend development. It lets you test wallet authentication and transaction signing against the emulator without a real wallet.

**Only needed for frontend development.** If you're only writing and testing Cadence contracts, skip this.

## Prerequisites

- Flow CLI installed (see [flow-cli.md](flow-cli.md))
- Flow Emulator running (see [emulator.md](emulator.md))
- Contracts deployed to emulator (`flow project deploy`)

## Setup

Run three processes in separate terminals:

```bash
# Terminal 1: Start emulator
flow emulator start

# Terminal 2: Deploy contracts
flow project deploy --network emulator

# Terminal 3: Start dev wallet
flow dev-wallet
```

The dev wallet runs on port **8701**. A test harness is available at `http://localhost:8701/harness`.

## Frontend Configuration

### Using FCL directly
```javascript
import * as fcl from '@onflow/fcl';

fcl.config()
  .put('accessNode.api', 'http://localhost:8888')
  .put('discovery.wallet', 'http://localhost:8701/fcl/authn');
```

### Using React SDK FlowProvider
```typescript
import { FlowProvider } from '@onflow/react-sdk';
import flowJson from '../flow.json';

<FlowProvider
  config={{
    accessNodeUrl: 'http://localhost:8888',
    flowNetwork: 'emulator',
    discoveryWallet: 'http://localhost:8701/fcl/authn',
  }}
  flowJson={flowJson}
>
  <App />
</FlowProvider>
```

## Important Notes

- The dev wallet is **only for local development** — never use with testnet or mainnet
- It provides pre-funded test accounts for signing transactions
- It simulates the same FCL authentication flow that real wallets use
- When switching to testnet/mainnet, replace the discovery wallet URL (see [frontend-sdk.md](frontend-sdk.md))

## Documentation

- Official docs: https://developers.flow.com/tools/flow-dev-wallet
