# useFlowRevertibleRandom

React hook for fetching `revertibleRandom` values from Flow via a Cadence script. Re-exported from `@onflow/react-sdk`; lives in `onflow/fcl-js` at `packages/react-core/src/hooks/useFlowRevertibleRandom.ts`.

## When to use

| Use case | Use this hook? |
|---|---|
| Animations, loading skeletons, splash variations | ✅ Yes |
| Demo dice / coin-flip with no payoff | ✅ Yes |
| Lottery, raffle, NFT mint reveal, game payout | ❌ No — use commit-reveal on chain |
| Anything tied to value or user economic outcome | ❌ No |

The hook reads on-chain randomness via a script. **Scripts can be re-executed for free until the user gets a result they like** — a frontend that ties value to a script-read random is exploitable. For economic outcomes, use the `RandomConsumer` commit-reveal flow on the contract side and surface the fulfilled value to React via `useFlowQuery` or `useFlowEvents`.

## Signature

```ts
const { data, isLoading, error, refetch } = useFlowRevertibleRandom({
  min,        // optional UInt256 (decimal string) — default 0
  max,        // required UInt256 (decimal string) — exclusive upper bound
  count,      // optional Int — number of values to fetch (default 1)
  query,      // optional TanStack query options (staleTime, enabled, etc.)
});
```

`data` is `Array<{ blockHeight: string; value: string }>` where `value` is a UInt256 in decimal string form. The hook returns `count` values, all sourced from the same query block.

## Quick example

```tsx
import { useFlowRevertibleRandom } from '@onflow/react-sdk';

function FlavorEmoji() {
  const { data } = useFlowRevertibleRandom({
    max: '4',
    count: 1,
  });

  if (!data?.[0]) return null;
  const idx = Number(BigInt(data[0].value)) % 4;
  return <span>{['🌟', '🎉', '🎯', '🚀'][idx]}</span>;
}
```

## Refetch to advance

Within a single block, repeated queries return the same value. To get a fresh value, either:

1. Wait for a new block to be sealed (typically ~1s on Flow), then call `refetch()`.
2. Set `query: { staleTime: 0 }` and trigger a refetch via user action.

```tsx
const { data, refetch } = useFlowRevertibleRandom({ max: '100', count: 1 });
return <button onClick={() => refetch()}>Re-roll</button>;
```

The block height in `data[0].blockHeight` tells you which block the value came from — useful if you want to display it or detect when the value actually changed.

## TanStack caching

Inherits all TanStack Query behavior. By default the result is cached and re-used until stale. Override via `query`:

```tsx
useFlowRevertibleRandom({
  max: '100',
  query: { staleTime: 0, refetchInterval: 1000 },
});
```

## Working with UInt256 strings

Values come back as decimal strings to avoid JavaScript precision loss. Convert with `BigInt`:

```tsx
const v = BigInt(data[0].value);
const inRange = Number(v % 100n);  // 0..99
```

Don't use `parseInt` or `Number(value)` directly on UInt256 — overflow loses precision past 2^53.

## Companion patterns

For value-bearing flows, mix this hook with the contract-side commit-reveal:

1. User clicks "play" → React calls a `useFlowMutate` that sends a commit transaction (locks the wager, requests randomness).
2. React subscribes via `useFlowEvents` to the `RandomnessFulfilled` event from `RandomConsumer`.
3. When the event arrives, render the result. Optionally trigger a follow-up reveal mutation.
4. Use `useFlowRevertibleRandom` ONLY for cosmetic UI variations during the wait.

## See also

- `hooks.md` — full hook catalog, including `useFlowMutate` and `useFlowEvents`
- `cadence-lang/references/randomness.md` — when to use which on-chain API
- `cadence-audit/references/randomness-vulns.md` — why script-read randomness is unsafe for value
