# Cadence CU Optimization

Flow hard-caps every transaction at **9,999 CU**. Fees have two components:
- Inclusion fee: 0.0001 FLOW (fixed)
- Execution fee: CU × price_per_CU (≈ 4.0e-5 FLOW/CU)

Extract real CU from the `FlowFees.FeesDeducted` event `amount` field after any sealed transaction.

## CU Cost by Operation Type

| Operation | CU cost | Notes |
|-----------|---------|-------|
| FT transfer (reference) | ~19 CU | Baseline for fee math |
| `{UInt64: T}` dict write | ~7–8 CU | 2 hash passes + B+ tree traversal |
| `[T]` array append | ~0.3–0.5 CU | Bounds check only |
| `account.storage.borrow<&T>` | ~5 CU | Charged even if resource unchanged |
| `StoragePath(identifier: s)` construction | ~1 CU | String allocation |
| EVM `dryCall` (simple view) | ~50–100 CU | Varies with return data size |
| EVM `coa.call` (state mutating) | ~200–500 CU | Plus EVM gas converted to CU |

## High-CU Patterns to Avoid

**Dict writes inside loops**
```cadence
// ❌ 7–8 CU per iteration
for id in ids {
    self.registry[id] = value
}

// ✅ ~0.4 CU per iteration — use array if keyed access not needed
self.items.append(value)
```

**Borrow inside loops**
```cadence
// ❌ ~5 CU wasted per iteration even if resource unchanged
for i in items {
    let r = self.account.storage.borrow<&Counter>(from: /storage/counter)!
    r.increment()
}

// ✅ borrow once, use reference for all iterations
let counter = self.account.storage.borrow<&Counter>(from: /storage/counter)!
for i in items {
    counter.increment()
}
```

**Path construction inside loops**
```cadence
// ❌ ~1 CU per iteration
for id in ids {
    let path = StoragePath(identifier: "vault_".concat(id.toString()))!
}

// ✅ construct once outside loop when path is constant
let path = StoragePath(identifier: "vault_main")!
```

**Individual counter increments**
```cadence
// ❌ N transactions of 5 CU each
for _ in items {
    self.head = self.head + 1
}

// ✅ single bulk update
self.head = self.head + UInt64(items.length)
```

## Resource Inlining

Resources with total encoded size ≤ 512 bytes are inlined in their parent — zero extra storage read. If a resource exceeds 512 bytes it spills to a separate slot, adding CU on every access.

```
Rough field sizes (encoded):
  UInt64      8 bytes
  UFix64      8 bytes
  Address    20 bytes
  String      variable (length prefix + content)
  Bool        1 byte

Check: sum(field_sizes) ≤ 512 bytes → inlined → no extra CU
```

## Composite Key Packing

```cadence
// ❌ String key: 85 bytes, hashed twice per write
let key = fromAddr.toString().concat("->").concat(toAddr.toString())
self.edges[key] = weight

// ✅ packed UInt64: 8 bytes, same hash cost
let key: UInt64 = (UInt64(fromId) << 32) | UInt64(toId)
self.edges[key] = weight
```

Only works when both components fit in UInt32 (max value ~4.3 billion each).

## Sweep Methodology for Measuring MAX_SAFE_N

Run the transaction at increasing N values and record the fee from `FlowFees.FeesDeducted`:

```
N = [64, 128, 256, 512, 768, 1024, 1280, 1536]
```

1. Find the cliff where the tx fails — binary-search the exact limit at ±4 entries.
2. Plot fee vs N: y-intercept = fixed overhead, slope = CU/entry.
3. Set MAX_SAFE_N = highest passing N with ≥10% headroom below 9,999 CU.

```
RECOMMENDED_FEE_PER_ENTRY = (FEE_PER_TX / MAX_SAFE_N) × 1.10
```

## EVM CU Interaction

Cross-VM calls consume CU on the Cadence side in addition to EVM gas:

| Call type | Cadence CU overhead | EVM gas |
|-----------|---------------------|---------|
| `EVM.dryCall` simple view | ~50–100 CU | consumed but not charged |
| `EVM.dryCall` large array return | ~200–800 CU | scales with return data size |
| `coa.call` state mutating | ~200–500 CU | charged separately in FLOW |

Decode `EVM.Result.data` inline — passing a large `[UInt8]` as a function argument costs extra CU at the function boundary.
