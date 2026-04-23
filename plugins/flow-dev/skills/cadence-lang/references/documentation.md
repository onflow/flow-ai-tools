# Cadence Documentation Conventions

Generated Cadence code should be documented, especially when it introduces new contract APIs or non-obvious logic.

## What Must Be Documented

- Add doc comments to contracts, resources, structs, resource interfaces, struct interfaces, fields, functions, and events when they are part of the design a reader needs to understand.
- Doc comments may use `///` line comments or `/** ... */` block comments. Prefer `///` for generated code unless there is a clear reason to use block comments.
- Add doc comments to callable functions, especially public or entitled functions that other code or users are expected to call.
- Keep the focus on types and functions first. That is the minimum bar for generated code.

## Markdown Support

- Cadence doc comments support Markdown. Use standard Markdown formatting when it improves readability.
- Prefer `**bold labels**`, bullet lists, and inline code over ad hoc annotation syntax.
- Do not use `@param` or `@return`. The reviewed PR discussion explicitly rejects that format because the LSP does not render it well.

## How To Write Doc Comments

- Describe purpose and behavior, not syntax.
- Mention invariants, side effects, entitlement requirements, important preconditions, and panic conditions when they matter to safe usage.
- Keep comments concise and directly above the declaration they describe.
- Use backticks for identifiers such as function names, parameter names, types, fields, and entitlements.

```cadence
/// Tracks escrow state and releases payment only after delivery is confirmed.
access(all) contract Escrow {
    /// Emits when escrowed funds are released to the seller.
    access(all) event PaymentReleased(amount: UFix64, seller: Address)

    /// Releases escrowed funds after the contract has verified delivery.
    access(ReleasePayment) fun releasePayment(): UFix64 {
        // ...
    }
}
```

## Function Documentation Format

Function documentation has three parts, in order:

1. Description: one or more sentences explaining what the function does. If the function can panic or has caller-visible side effects, say so here.
2. `**Parameters**` block: only include this when the function takes parameters. Put `**Parameters**` on its own doc-comment line, then add one bullet per parameter using inline code for the parameter name followed by its description.
3. `**Returns**` block: only include this when the function returns a non-`Void` value. Put `**Returns**` inline with a prose description of the returned value.

Separate blocks with blank doc-comment lines.

```cadence
/// Consumes one unit of allowance and creates a new yield vault.
/// Panics if allowance is exhausted.
///
/// **Parameters**
/// - `name`: Name of the registered strategy to create a vault for.
///
/// **Returns** A new `YieldVault` to be saved in the caller's storage.
access(all) fun createYieldVault(name: String): @{FlowYieldVaultsInterfaces.YieldVault} {
    // ...
}
```

For short functions where the description already explains the parameters and return value in prose, the `**Parameters**` and `**Returns**` blocks can be omitted.

```cadence
/// Returns `|numer - denom| / denom`, or `0.0` when `denom = 0`.
/// Used to compare `|1 - (numer / denom)|` without `UFix64` underflow.
view access(all) fun absDeviationFromOne(_ numer: UFix64, _ denom: UFix64): UFix64 {
    // ...
}
```

## Inline Comments In Function Bodies

- Add focused `//` comments for non-obvious logic inside function bodies.
- Use them to explain phase boundaries, resource movement, capability usage, security-sensitive checks, and invariant enforcement.
- Do not narrate trivial statements line by line.

```cadence
access(all) fun fulfill(orderID: UInt64) {
    // Borrow instead of load/save so the resource stays in account storage.
    let escrow = self.orders[orderID]
        ?? panic("Order with ID \(orderID) not found")

    // Mark delivered before release so the post-state matches the payment guard.
    escrow.markDelivered()
    self.releaseEscrow(orderID: orderID)
}
```

## Best Practices

- Avoid Markdown headings (`#`, `##`) and horizontal rules inside doc comments. Use `**Parameters**` and `**Returns**` when you need section-like structure.
- Keep the description at the top. Do not interleave description text with the `**Parameters**` or `**Returns**` blocks.
- Put `**Returns**` after `**Parameters**`.
- When a function panics, say so in the description instead of inventing a separate panic block.
