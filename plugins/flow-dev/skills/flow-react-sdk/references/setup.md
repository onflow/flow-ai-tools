# Flow React SDK Setup

## Installation

```bash
npm install @onflow/react-sdk
```

## FlowProvider

Wrap your app with `FlowProvider` to configure the Flow connection:

### Standard React
```tsx
import { FlowProvider } from '@onflow/react-sdk';
import flowJSON from '../flow.json';

function Root() {
  return (
    <FlowProvider
      config={{
        accessNodeUrl: 'https://access-mainnet.onflow.org',
        flowNetwork: 'mainnet',
        appDetailTitle: 'My On Chain App',
        appDetailIcon: 'https://example.com/icon.png',
        appDetailDescription: 'A decentralized app on Flow',
        appDetailUrl: 'https://myonchainapp.com',
      }}
      flowJson={flowJSON}
      darkMode={false}
    >
      <App />
    </FlowProvider>
  );
}
```

### Next.js (Client Component)
```tsx
'use client';

import { FlowProvider } from '@onflow/react-sdk';
import flowJSON from '../flow.json';

export default function FlowProviderWrapper({ children }: { children: React.ReactNode }) {
  return (
    <FlowProvider
      config={{
        accessNodeUrl: 'https://access-mainnet.onflow.org',
        flowNetwork: 'mainnet',
        appDetailTitle: 'My On Chain App',
      }}
      flowJson={flowJSON}
    >
      {children}
    </FlowProvider>
  );
}
```

### Next.js Layout
```tsx
import FlowProviderWrapper from '@/components/FlowProviderWrapper';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <FlowProviderWrapper>{children}</FlowProviderWrapper>
      </body>
    </html>
  );
}
```

## FlowProvider Config Properties

| Property | Type | Description |
|----------|------|-------------|
| `accessNodeUrl` | `string` | Flow access node URL |
| `flowNetwork` | `string` | `"mainnet"`, `"testnet"`, or `"emulator"` |
| `appDetailTitle` | `string` | App name shown in wallet |
| `appDetailIcon` | `string` | App icon URL |
| `appDetailDescription` | `string` | App description |
| `appDetailUrl` | `string` | App URL |
| `walletconnectProjectId` | `string` | WalletConnect project ID (optional, enables WalletConnect) |

## FlowProvider Props

| Prop | Type | Description |
|------|------|-------------|
| `config` | `FlowConfig` | Configuration object (see above) |
| `flowJson` | `object` | Imported `flow.json` for contract resolution |
| `darkMode` | `boolean` | Dark mode toggle (default: `false`) |
| `theme` | `ThemeConfig` | Custom theme overrides |

## Network Configuration

```tsx
// Mainnet
config={{ accessNodeUrl: 'https://access-mainnet.onflow.org', flowNetwork: 'mainnet' }}

// Testnet
config={{ accessNodeUrl: 'https://access-testnet.onflow.org', flowNetwork: 'testnet' }}

// Emulator
config={{ accessNodeUrl: 'http://127.0.0.1:8888', flowNetwork: 'emulator' }}
```

## Theming

Pass a custom theme to `FlowProvider` to override default colors:

```tsx
const customTheme = {
  colors: {
    primary: "flow-bg-purple-600 dark:flow-bg-purple-400",
    primaryForeground: "flow-text-white dark:flow-text-purple-900",
    secondary: "flow-bg-emerald-500 dark:flow-bg-emerald-400",
    accent: "flow-bg-purple-700 dark:flow-bg-purple-300",
    border: "flow-border-purple-200 dark:flow-border-purple-700",
  }
};

<FlowProvider config={config} theme={customTheme}>
  <App />
</FlowProvider>
```

Theme color properties: `primary`, `primaryForeground`, `secondary`, `secondaryForeground`, `accent`, `background`, `foreground`, `muted`, `mutedForeground`, `border`, `success`, `error`, `link`. Only specify colors you want to override.

## Dark Mode

Controlled by parent app via `darkMode` prop on FlowProvider:
- `darkMode={false}` — Light mode (default)
- `darkMode={true}` — Dark mode
- Dynamically changeable at runtime

```tsx
const { isDark } = useDarkMode();  // Access in components
```

Note: SDK does NOT auto-follow system preferences — parent app manages state.

## Utility Hooks

### useFlowClient
Returns the `FlowClient` for the current FlowProvider context.
```tsx
const client = useFlowClient();
```

### useFlowConfig
Accesses current configuration.
```tsx
const config = useFlowConfig();
// config.flowNetwork, config.accessNodeUrl
```

### useFlowChainId
Returns the current network: `"testnet"`, `"mainnet"`, or `"emulator"`.
```tsx
const { data: chainId } = useFlowChainId();
```
