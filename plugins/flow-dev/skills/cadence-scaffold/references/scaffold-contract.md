# Scaffold: Cadence Contract

## Interview the User

Before generating, ask for:
1. **Contract name and purpose** — what does it do?
2. **Contract type** — NFT, FT token, or general contract?
3. **Key resources and operations** — what resources are needed?
4. **Admin functionality** — is admin access required?

## Security Rules (Always Apply)

- All fields `access(self)` by default; expose only what's needed
- Named constants for all storage paths
- Complete `init()` — initialize all state and paths
- Emit events for all significant state changes
- Admin singleton created in `init()` only
- Borrow references instead of load/save cycles
- Existence checks before storage writes
- Entitlements for all privileged operations
- No `auth(...) &Account` parameters in contract functions
- No public admin resource creation
- No capability-typed public fields

## Contract Structure Template

```cadence
import "FungibleToken"  // Only import what you need

access(all) contract <Name> {

    // ── Events ──
    access(all) event ContractInitialized()
    access(all) event <ActionPerformed>(param: Type)

    // ── State (access(self) fields) ──
    access(self) var totalSupply: UInt64

    // ── Paths (access(all) constants) ──
    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    // ── Entitlements ──
    entitlement Admin
    entitlement Withdraw

    // ── Resource Interfaces ──
    access(all) resource interface PublicInterface {
        access(all) view fun getData(): String
    }

    // ── Resources ──
    access(all) resource MyResource: PublicInterface {
        access(self) var data: String

        access(all) view fun getData(): String {
            return self.data
        }

        access(Admin) fun updateData(newData: String) {
            self.data = newData
        }

        init(data: String) {
            self.data = data
        }
    }

    // ── Admin Resource (singleton) ──
    access(all) resource Admin {
        access(all) fun createResource(data: String): @MyResource {
            <Name>.totalSupply = <Name>.totalSupply + 1
            return <- create MyResource(data: data)
        }
    }

    // ── Public Functions (minimal set) ──
    access(all) view fun getTotalSupply(): UInt64 {
        return self.totalSupply
    }

    // ── Init ──
    init() {
        self.totalSupply = 0
        self.StoragePath = /storage/<name>Storage
        self.PublicPath = /public/<name>Public

        // Create admin singleton
        let admin <- create Admin()
        self.account.storage.save(<-admin, to: /storage/<name>Admin)

        emit ContractInitialized()
    }
}
```

## NFT Contract Additions

If the contract is an NFT, also:
- Import `NonFungibleToken` and `MetadataViews`
- Implement `NonFungibleToken.NFT` on the NFT resource
- Implement `getViews()` and `resolveView()` with Display, Serial, NFTCollectionData
- Implement `NonFungibleToken.Collection` on the Collection resource
- Add `createEmptyCollection()` at contract level
- Use versioned storage paths (`/storage/MyNFTV1Collection`)
- One contract per `.cdc` file

## FT Contract Additions

If the contract is a fungible token, also:
- Import `FungibleToken`
- Implement `FungibleToken.Vault` with Provider, Receiver, Balance
- Use `access(Withdraw)` entitlement for withdraw
- `deposit` should be `access(all)`
- Publish receiver capability publicly (no entitlements)

## Post-Generation

After generating:
- Add `///` doc comments for the contract, each public-facing resource/struct/event, and each externally callable function.
- Add inline comments explaining security decisions for each access modifier and entitlement choice.
- Add inline comments anywhere resource movement, capability publication, or invariant enforcement would otherwise be hard to follow.

> **See also:** `cadence-lang` skill → `access-control.md` and `entitlements.md` for access rules, `design-patterns.md` for naming and storage patterns, `anti-patterns.md` for what to avoid. For NFT contracts, see `cadence-tokens` skill → `nft-standards.md`. Use `cadence-audit` skill to review generated code before deployment. Use `flow-cli` skill to deploy with `flow accounts add-contract`.
