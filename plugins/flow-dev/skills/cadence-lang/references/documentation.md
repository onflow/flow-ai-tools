# Cadence Documentation Conventions

Generated Cadence code should be documented, especially when it introduces new contract APIs or non-obvious logic.

## What Must Be Documented

- Add doc comments (`///`) to contracts, resources, structs, resource interfaces, struct interfaces, and events when they are part of the design a reader needs to understand.
- Add doc comments (`///`) to callable functions, especially public or entitled functions that other code or users are expected to call.
- Keep the focus on types and functions first. That is the minimum bar for generated code.

## How To Write Doc Comments

- Describe purpose and behavior, not syntax.
- Mention invariants, side effects, entitlement requirements, or important preconditions when they matter to safe usage.
- Keep comments concise and directly above the declaration they describe.

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
