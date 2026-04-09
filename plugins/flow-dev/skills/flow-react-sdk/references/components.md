# Flow React SDK — UI Components

All components use Tailwind CSS and support light/dark themes via FlowProvider.

## Connect

Drop-in wallet connection with balance display and profile modal.

```tsx
import { Connect } from '@onflow/react-sdk';

<Connect
  onConnect={() => console.log('Connected!')}
  onDisconnect={() => console.log('Logged out')}
  balanceType="cadence"  // "cadence" | "evm" | "combined"
/>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `variant` | `ButtonProps["variant"]` | `"primary"` | Button style |
| `onConnect` | `() => void` | — | Called after successful auth |
| `onDisconnect` | `() => void` | — | Called after logout |
| `balanceType` | `"cadence" \| "evm" \| "combined"` | `"cadence"` | Which balance to show |
| `balanceTokens` | `TokenConfig[]` | — | Custom token configs (`symbol`, `name`, `vaultIdentifier` or `erc20Address`) |
| `modalConfig` | `ConnectModalConfig` | — | Profile modal settings |
| `modalEnabled` | `boolean` | `true` | Show profile modal on click |

Enable WalletConnect by adding `walletconnectProjectId` to FlowProvider config.

## Profile

Standalone wallet info display with address, balance, and scheduled transactions.

```tsx
import { Profile } from '@onflow/react-sdk';

<Profile
  balanceType="combined"
  onDisconnect={() => console.log('Disconnected')}
/>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `onDisconnect` | `() => void` | — | Disconnect callback |
| `balanceType` | `"cadence" \| "evm" \| "combined"` | `"cadence"` | Balance type |
| `balanceTokens` | `TokenConfig[]` | — | Token configs |
| `profileConfig` | `ProfileConfig` | — | Scheduled tx display settings |

## TransactionButton

Button that executes a Flow transaction with built-in loading states.

```tsx
import { TransactionButton } from '@onflow/react-sdk';

const myTransaction = {
  cadence: `
    transaction() {
      prepare(acct: &Account) {
        log("Hello from ", acct.address)
      }
    }
  `,
  args: (arg, t) => [],
  limit: 100,
};

<TransactionButton
  transaction={myTransaction}
  label="Say Hello"
  variant="primary"
  mutation={{
    onSuccess: (txId) => console.log('Sent:', txId),
    onError: (err) => console.error('Failed:', err),
  }}
/>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `transaction` | `FCLMutateParams` | — | Transaction object (`cadence`, `args`, `limit`) |
| `label` | `string` | `"Execute Transaction"` | Button text |
| `mutation` | `UseMutationOptions` | — | TanStack mutation options (`onSuccess`, `onError`) |
| `...buttonProps` | `ButtonProps` | — | All button props except `onClick` and `children` |

## TransactionDialog

Dialog showing real-time transaction status updates.

```tsx
import { TransactionDialog } from '@onflow/react-sdk';

<TransactionDialog
  open={isOpen}
  onOpenChange={setIsOpen}
  txId="6afa38b7..."
  pendingTitle="Sending..."
  successTitle="All done!"
  closeOnSuccess
/>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `open` | `boolean` | — | Dialog visibility |
| `onOpenChange` | `(open: boolean) => void` | — | Visibility callback |
| `txId` | `string` | — | Transaction or scheduled tx ID to track |
| `onSuccess` | `() => void` | — | Called on success |
| `pendingTitle` | `string` | — | Custom pending title |
| `pendingDescription` | `string` | — | Custom pending description |
| `successTitle` | `string` | — | Custom success title |
| `successDescription` | `string` | — | Custom success description |
| `closeOnSuccess` | `boolean` | — | Auto-close on success |

## TransactionLink

Network-aware link to block explorer.

```tsx
import { TransactionLink } from '@onflow/react-sdk';

<TransactionLink txId="your-tx-id" />
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `txId` | `string` | — | Transaction ID |
| `variant` | `ButtonProps["variant"]` | `"link"` | Button style |

## NftCard

Render an NFT with image, metadata, traits, and action buttons.

```tsx
import { NftCard } from '@onflow/react-sdk';

<NftCard
  accountAddress="0x1234..."
  tokenId="12345"
  publicPathIdentifier="A.0b2a3299cc857e29.TopShot.Collection"
  showTraits={true}
  showExtra={true}
  actions={[
    { title: 'Transfer', onClick: async () => { /* ... */ } },
    { title: 'List for Sale', onClick: async () => { /* ... */ } },
  ]}
/>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `accountAddress` | `string` | — | Account owning the NFT |
| `tokenId` | `string \| number` | — | NFT ID |
| `publicPathIdentifier` | `string` | — | Collection public path |
| `showTraits` | `boolean` | `false` | Show traits (up to 4) |
| `showExtra` | `boolean` | `false` | Show serial, rarity, links |
| `actions` | `NftCardAction[]` | — | Action buttons (`title`, `onClick`) |

## ScheduledTransactionList

Display scheduled transactions for an account with cancel support.

```tsx
import { ScheduledTransactionList } from '@onflow/react-sdk';

<ScheduledTransactionList
  address="0x1234..."
  filterHandlerTypes={['A.1234.MyContract.Handler']}
  cancelEnabled={true}
/>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `address` | `string` | — | Account address |
| `filterHandlerTypes` | `string[]` | — | Filter by handler type IDs |
| `cancelEnabled` | `boolean` | `true` | Show cancel buttons |
