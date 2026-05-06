# Cadence Documentation Conventions

Generated Cadence code should be documented, especially when it introduces new contract APIs or non-obvious logic.

## What Must Be Documented

- Add doc comments to contracts, resources, structs, resource interfaces, struct interfaces, fields, functions, and events when they are part of the design a reader needs to understand.
- Doc comments may use `///` line comments or `/** ... */` block comments. Prefer `///` for generated code unless there is a clear reason to use block comments.
- Add doc comments to callable functions, especially public or entitled functions that other code or users are expected to call.
- Keep the focus on types and functions first. That is the minimum bar for generated code.

## Markdown Support

- Cadence doc comments support Markdown. Use standard Markdown formatting when it improves readability.
- Use inline code, emphasis, and bullet lists where they improve readability.
- Keep Markdown simple so generated documentation remains structured and readable.

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
2. Parameter tags: when the function takes parameters, document each one with `@param`, followed by the parameter name, a colon, and the parameter description.
3. Return tag: when the function returns a non-`Void` value, document it with `@return`, followed by a prose description of the returned value.

Separate blocks with blank doc-comment lines.

```cadence
/// This is the description of the function. This function adds two values.
///
/// @param a: First integer value to add
/// @param b: Second integer value to add
/// @return Addition of the two arguments `a` and `b`
///
access(all) fun add(a: Int, b: Int): Int {
    // ...
}
```

Do not mix description text with parameter or return documentation after the tags have started.

```cadence
/// This is the description of the function.
///
/// @param a: First integer value to add
/// @param b: Second integer value to add
///
/// This function adds two values. However, this is not the proper way to document it.
/// This part of the description is not in the proper place.
///
/// @return Addition of the two arguments `a` and `b`
access(all) fun add(a: Int, b: Int): Int {
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

- Avoid headings and horizontal rules inside doc comments. The `docgen` README warns they can conflict with generated output structure.
- Keep the function description at the top and keep `@param` / `@return` documentation grouped below it.
- Use inline code when referring to identifiers such as parameter names and function names.
- When a function panics, say so in the description.
