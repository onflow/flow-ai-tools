# Flow React SDK — Cadence Hooks

All hooks return TanStack Query results (`data`, `isLoading`, `error`, `refetch`). Mutation hooks return `mutate`, `mutateAsync`, `isPending`, `error`, `data`.

## Authentication

### useFlowCurrentUser
Manage wallet authentication state.

```tsx
const { user, authenticate, unauthenticate } = useFlowCurrentUser();

// user.loggedIn — boolean
// user.addr — Flow address (e.g. "0x1234...")
// authenticate() — triggers wallet login
// unauthenticate() — logs out
```

### useFlowAuthz
Returns authorization function for transactions.

```tsx
const authz = useFlowAuthz();

// Pass to transaction authorizations
mutate({ cadence: '...', authorizations: [authz] });
```

Pass a custom `AuthorizationFunction` to override wallet authorization.

## Querying

### useFlowQuery
Execute read-only Cadence scripts.

```tsx
const { data, isLoading, error } = useFlowQuery({
  cadence: `
    access(all) fun main(a: Int, b: Int): Int {
      return a + b
    }
  `,
  args: (arg, t) => [arg(1, t.Int), arg(2, t.Int)],
});
// data === 3
```

Supports all TanStack Query options (`staleTime`, `refetchInterval`, etc.).

### useFlowQueryRaw
Same as `useFlowQuery` but returns raw, non-decoded response data for manual parsing.

### useFlowAccount
Fetch account details (balance, keys, contracts).

```tsx
const { data: account } = useFlowAccount({ address: '0x1234...' });
// account.address, account.balance, account.code
```

### useFlowBlock
Fetch block information.

```tsx
// Latest sealed block
const { data: block } = useFlowBlock({ sealed: true });

// By height
const { data: block } = useFlowBlock({ height: 12345 });

// By ID
const { data: block } = useFlowBlock({ id: 'abc123...' });
```

Only supply one of `sealed`, `height`, or `id`.

### useFlowNftMetadata
Fetch NFT metadata including display, traits, rarity, and collection details.

```tsx
const { data: nft } = useFlowNftMetadata({
  accountAddress: '0x1234...',
  tokenId: '42',
  publicPathIdentifier: 'A.0b2a3299cc857e29.TopShot.Collection',
});
// nft.name, nft.description, nft.thumbnailUrl
// nft.traits, nft.rarity, nft.serialNumber
// nft.collectionName, nft.collectionExternalUrl
```

## Mutations

### useFlowMutate
Submit Cadence transactions.

```tsx
const { mutate, isPending, error, data: txId } = useFlowMutate();

mutate({
  cadence: `
    transaction(amount: UFix64) {
      prepare(acct: &Account) {
        log(acct.address)
      }
    }
  `,
  args: (arg, t) => [arg("10.0", t.UFix64)],
  limit: 100,
});
```

`data` returns the transaction ID after submission.

## Events

### useFlowEvents
Subscribe to real-time blockchain events.

```tsx
useFlowEvents({
  eventTypes: ['A.0xDeaDBeef.Contract.EventName'],
  onEvent: (event) => {
    console.log('Event received:', event);
  },
  onError: (error) => {
    console.error('Subscription error:', error);
  },
});
```

| Parameter | Description |
|-----------|-------------|
| `eventTypes` | Filter by event type identifiers |
| `addresses` | Filter by Flow addresses |
| `contracts` | Filter by contract identifiers |
| `startBlockId` | Start from specific block ID |
| `startHeight` | Start from specific block height |
| `opts.heartbeatInterval` | Subscription heartbeat interval |

## Transactions

### useFlowTransaction
Fetch decoded transaction details by ID.

```tsx
const { data: tx } = useFlowTransaction({ txId: '0xabc123...' });
// tx.id, tx.gasLimit, tx.arguments
```

### useFlowTransactionStatus
Monitor transaction status in real-time.

```tsx
const { transactionStatus, error } = useFlowTransactionStatus({ id: '0xabc123...' });
// transactionStatus?.statusString
```

## Scheduled Transactions

### useFlowScheduledTransaction
Fetch single scheduled transaction details.

```tsx
const { data: scheduled } = useFlowScheduledTransaction({
  txId: '42',
  includeHandlerData: true,
});
// scheduled.id, scheduled.status, scheduled.priority
// scheduled.fees, scheduled.scheduledTimestamp
```

### useFlowScheduledTransactionList
List all scheduled transactions for an account.

```tsx
const { data: list } = useFlowScheduledTransactionList({ account: '0x1234...' });
```

### useFlowScheduledTransactionCancel
Cancel a scheduled transaction and refund fees.

```tsx
const { cancelTransaction, isPending } = useFlowScheduledTransactionCancel();
cancelTransaction('42');
```

### useFlowScheduledTransactionSetup
Initialize the Transaction Scheduler Manager resource.

```tsx
const { setup, isPending } = useFlowScheduledTransactionSetup();
setup();
```

## Randomness

### useFlowRevertibleRandom
Generate pseudorandom values tied to blockchain blocks.

```tsx
const { data: randoms } = useFlowRevertibleRandom({
  max: '1000',
  count: 3,
});
// randoms[0].value, randoms[0].blockHeight
```

Values are deterministic per block — same call in same block returns same values. For unpredictable randomness, use commit-reveal scheme in transactions.
