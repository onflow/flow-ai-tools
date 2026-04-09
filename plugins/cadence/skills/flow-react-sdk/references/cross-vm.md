# Flow React SDK — Cross-VM Hooks

Cross-VM hooks enable hybrid Cadence + EVM operations: atomic batch transactions, token/NFT bridging between Cadence and Flow EVM, and cross-chain balance queries.

## Batch Transactions

### useCrossVmBatchTransaction
Execute multiple EVM transactions in a single atomic Cadence transaction.

```tsx
const { mutate, mutateAsync, isPending, error, data: txId } = useCrossVmBatchTransaction();

mutate({
  calls: [
    {
      address: '0xEVMContractAddress',
      abi: contractAbi,
      functionName: 'approve',
      args: [spenderAddress, amount],
    },
    {
      address: '0xEVMContractAddress',
      abi: contractAbi,
      functionName: 'stake',
      args: [amount],
      gasLimit: 300000n,
    },
  ],
  mustPass: true,  // All calls must succeed or entire tx reverts
});
```

**EvmBatchCall properties:**

| Property | Type | Description |
|----------|------|-------------|
| `address` | `string` | Target EVM contract address |
| `abi` | `Abi` | Contract ABI fragment |
| `functionName` | `string` | Function to call |
| `args` | `readonly unknown[]` | Function arguments (optional) |
| `gasLimit` | `bigint` | Gas limit for this call (optional) |
| `value` | `bigint` | Value to send with call (optional) |

## Cross-Chain Balances

### useCrossVmTokenBalance
Fetch token balance across both Cadence and EVM environments.

```tsx
const { data: balance } = useCrossVmTokenBalance({
  owner: '0xCadenceAddress',
  vaultIdentifier: '0x1cf0e2f2f715450.FlowToken.Vault',
  // OR
  erc20AddressHexArg: '0xERC20Address',
});

// balance.cadence.formatted  — e.g. "123.45"
// balance.evm.formatted
// balance.combined.formatted
// balance.cadence.value — bigint
// balance.cadence.precision — number
```

Must provide `owner` AND one of `vaultIdentifier` or `erc20AddressHexArg`.

**TokenBalance structure:** `{ value: bigint, formatted: string, precision: number }`

## Transaction Status

### useCrossVmTransactionStatus
Subscribe to status updates for Cross-VM transactions, including EVM call outcomes.

```tsx
const { transactionStatus, evmResults, error } = useCrossVmTransactionStatus({
  id: 'flow-tx-id',
});

// evmResults is an array of CallOutcome:
// { status: "passed" | "failed" | "skipped", hash?: string, errorMessage?: string }
```

## Token Bridging

### useCrossVmBridgeTokenToEvm
Bridge fungible tokens from Cadence to Flow EVM, then execute EVM calls atomically.

```tsx
const { crossVmBridgeTokenToEvm, isPending } = useCrossVmBridgeTokenToEvm();

crossVmBridgeTokenToEvm({
  vaultIdentifier: '0x1cf0e2f2f715450.FlowToken.Vault',
  amount: '100.0',
  calls: [
    {
      address: '0xEVMContract',
      abi: contractAbi,
      functionName: 'deposit',
      args: [],
      value: 100n * 10n ** 18n,
    },
  ],
});
```

### useCrossVmBridgeTokenFromEvm
Bridge fungible tokens from Flow EVM back to Cadence.

```tsx
const { crossVmBridgeTokenFromEvm, isPending } = useCrossVmBridgeTokenFromEvm();

crossVmBridgeTokenFromEvm({
  vaultIdentifier: '0x1cf0e2f2f715450.FlowToken.Vault',
  amount: '50000000000000000000',  // UInt256 string representation
});
```

## NFT Bridging

### useCrossVmBridgeNftToEvm
Bridge NFTs from Cadence to Flow EVM, then execute EVM calls atomically.

```tsx
const { crossVmBridgeNftToEvm, isPending } = useCrossVmBridgeNftToEvm();

crossVmBridgeNftToEvm({
  nftIdentifier: 'A.0x1234.MyNFT.NFT',
  nftIds: ['42', '43'],
  calls: [
    {
      address: '0xEVMMarketplace',
      abi: marketplaceAbi,
      functionName: 'listForSale',
      args: [tokenId, price],
    },
  ],
});
```

### useCrossVmBridgeNftFromEvm
Bridge NFTs from Flow EVM back to Cadence.

```tsx
const { crossVmBridgeNftFromEvm, isPending } = useCrossVmBridgeNftFromEvm();

crossVmBridgeNftFromEvm({
  nftIdentifier: 'A.0x1234.MyNFT.NFT',
  nftId: '42',
});
```

## Common Patterns

### Bridge + Swap + Stake (Atomic)
```tsx
const { mutate } = useCrossVmBatchTransaction();

// All calls execute atomically in one Cadence transaction
mutate({
  calls: [
    { address: tokenAddr, abi: erc20Abi, functionName: 'approve', args: [routerAddr, amount] },
    { address: routerAddr, abi: routerAbi, functionName: 'swap', args: [tokenIn, tokenOut, amount] },
    { address: stakingAddr, abi: stakingAbi, functionName: 'stake', args: [amount] },
  ],
  mustPass: true,
});
```

### Track Cross-VM Transaction
```tsx
const [txId, setTxId] = useState<string>();
const { transactionStatus, evmResults } = useCrossVmTransactionStatus({ id: txId });

// Check each EVM call result
evmResults?.forEach((result, i) => {
  if (result.status === 'failed') {
    console.error(`Call ${i} failed: ${result.errorMessage}`);
  }
});
```
