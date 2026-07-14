---
name: flow-react-sdk
description: |
  Guide for building React applications on the Flow blockchain using @onflow/react-sdk. Covers FlowProvider setup, Cadence hooks (useFlowQuery, useFlowMutate, useFlowCurrentUser, useFlowEvents), Cross-VM hooks for EVM bridging and batch transactions, and UI components (Connect, TransactionButton, TransactionDialog, NftCard). Built on TanStack Query with TypeScript support.
  TRIGGER when: building React apps on Flow, using @onflow/react-sdk, setting up FlowProvider, using Flow React hooks, "useFlowQuery", "useFlowMutate", "useFlowCurrentUser", "Connect component", "TransactionButton", "wallet connect react", "react flow app", "FCL React", "flow react hooks", "bridge tokens react", "cross-vm react", "NftCard", "useFlowEvents", "useFlowRevertibleRandom", "how to query Flow from React", "authenticate user in React", "random number in react flow".
  DO NOT TRIGGER when: writing Cadence contracts (use cadence-lang), configuring flow.json without React (use flow-project-setup), building non-React frontends or backends, auditing code (use cadence-audit).
---

# Flow React SDK

Build React apps on Flow with TypeScript-first hooks and components. Built on TanStack Query for automatic caching, retries, and background updates.

## Quick Start

```bash
npm install @onflow/react-sdk
```

```tsx
import { FlowProvider, Connect, useFlowQuery } from '@onflow/react-sdk';

function App() {
  return (
    <FlowProvider config={{ accessNodeUrl: 'https://access-mainnet.onflow.org', flowNetwork: 'mainnet' }}>
      <Connect />
      <MyComponent />
    </FlowProvider>
  );
}
```

## Navigation Map

| Task | Reference |
|------|-----------|
| Installation, FlowProvider, Next.js, theming, dark mode | [setup.md](references/setup.md) |
| Cadence hooks: query, mutate, auth, events, accounts, blocks, NFT metadata | [hooks.md](references/hooks.md) |
| Cross-VM hooks: EVM batch tx, token/NFT bridging, cross-chain balances | [cross-vm.md](references/cross-vm.md) |
| UI components: Connect, TransactionButton, TransactionDialog, NftCard | [components.md](references/components.md) |
| Randomness hook (cosmetic UI only — never economic) | [use-flow-revertible-random.md](references/use-flow-revertible-random.md) |

## Companion Skills

- **`cadence-lang`** — Consult when writing Cadence scripts/transactions used in `useFlowQuery` and `useFlowMutate`. The Cadence code passed to hooks must follow all language rules (access control, entitlements, resource handling).
- **`flow-project-setup`** — Consult for `flow.json` configuration that FlowProvider loads via `flowJson` prop. Contract addresses and network config must be aligned.
- **`flow-cli`** — Use to test scripts and transactions via CLI before integrating them into React hooks.
- **`cadence-tokens`** — Consult when using `useFlowNftMetadata` or building NFT/FT frontends for the correct MetadataViews and collection paths.
