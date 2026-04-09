# EVM Tooling on Flow

Flow EVM lets you deploy and interact with Solidity smart contracts on Flow using standard Ethereum tooling. Flow runs a full EVM interpreter (Geth v1.13) accessible via standard JSON-RPC.

**Only needed for Solidity/EVM development on Flow.** If you're writing Cadence contracts, skip this.

## Flow EVM Networks

| Network | Chain ID | RPC Endpoint | Block Explorer |
|---------|----------|--------------|----------------|
| Mainnet | 747 | `https://mainnet.evm.nodes.onflow.org` | `https://evm.flowscan.io` |
| Testnet | 545 | `https://testnet.evm.nodes.onflow.org` | `https://evm-testnet.flowscan.io` |

- Currency symbol: FLOW
- Token denomination: Atto-FLOW (1 FLOW = 10^18 Atto-FLOW), same as wei in Ethereum

## Hardhat

### Prerequisites
- Node.js installed

### Setup
```bash
npx hardhat init
npm install --save-dev @nomicfoundation/hardhat-toolbox-viem
npm install --save-dev @nomicfoundation/hardhat-ethers ethers
npm install --save-dev @openzeppelin/contracts
npm install --save-dev @openzeppelin/hardhat-upgrades
npm install dotenv
```

### hardhat.config.ts
```typescript
import type { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox-viem';

require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: '0.8.24',
  networks: {
    flow: {
      url: 'https://mainnet.evm.nodes.onflow.org',
      accounts: [process.env.DEPLOY_WALLET_1 as string],
    },
    flowTestnet: {
      url: 'https://testnet.evm.nodes.onflow.org',
      accounts: [process.env.DEPLOY_WALLET_1 as string],
    },
  },
  etherscan: {
    apiKey: {
      flow: 'abc',
      flowTestnet: 'abc',
    },
    customChains: [
      {
        network: 'flow',
        chainId: 747,
        urls: {
          apiURL: 'https://evm.flowscan.io/api',
          browserURL: 'https://evm.flowscan.io/',
        },
      },
      {
        network: 'flowTestnet',
        chainId: 545,
        urls: {
          apiURL: 'https://evm-testnet.flowscan.io/api',
          browserURL: 'https://evm-testnet.flowscan.io/',
        },
      },
    ],
  },
};

export default config;
```

### Environment
Create `.env`:
```
DEPLOY_WALLET_1=<YOUR_PRIVATE_KEY>
```

### Deploy and Verify
```bash
npx hardhat ignition deploy ./ignition/modules/MyContract.ts --network flowTestnet
hardhat ignition verify chain-545 --include-unrelated-contracts
```

## Foundry

### Install
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

This installs `forge`, `cast`, `anvil`, and `chisel`.

### Create Project
```bash
mkdir myproject && cd myproject
forge init
forge install OpenZeppelin/openzeppelin-contracts
```

### Build and Test
```bash
forge compile
forge test
```

### Deploy

**Important:** Use `--legacy` on all Flow commands — Flow does not support EIP-1559 transactions.

```bash
forge create --broadcast src/MyContract.sol:MyContract \
  --rpc-url https://testnet.evm.nodes.onflow.org \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --constructor-args <args> \
  --legacy
```

### Verify
```bash
forge verify-contract --rpc-url https://testnet.evm.nodes.onflow.org/ \
  --verifier blockscout \
  --verifier-url https://evm-testnet.flowscan.io/api \
  $CONTRACT_ADDRESS \
  src/MyContract.sol:MyContract
```

### Useful Cast Commands
```bash
# Generate a new wallet
cast wallet new

# Check balance
cast balance --ether --rpc-url https://testnet.evm.nodes.onflow.org $ADDRESS
```

## Remix IDE

1. Add Flow network to MetaMask (use the network details above)
2. Fund your account via the [Flow Faucet](https://faucet.flow.com/fund-account)
3. In Remix, select **Injected Provider - MetaMask** as the environment
4. Deploy and interact with contracts through MetaMask

## Flow-Specific Differences from Ethereum

- **Foundry requires `--legacy` flag** — Flow does not support EIP-1559 transactions via Foundry. Use `--legacy` on `forge create` and `cast send`.
- **Etherscan API key is a placeholder** — Flowscan uses Blockscout, which does not require a real API key. Use `"abc"` or any non-empty string in Hardhat's `etherscan.apiKey`.
- **Verification uses Blockscout** — not Etherscan. Foundry uses `--verifier blockscout`. Hardhat handles this via `customChains`.
- **No exportable private keys from Flow Wallet** — Use MetaMask or another standard EOA wallet for Hardhat/Foundry. Flow Wallet keys are not compatible.
- **Zero base fee** — Gas costs are extremely low since the EVM base fee is zero.
- **Flow Wallet gas sponsorship** — The Flow Wallet provides automatic gas sponsorship on both testnet and mainnet.

## Funding Testnet Accounts

Get testnet FLOW tokens from the faucet:
- Web: https://faucet.flow.com/fund-account
- CLI: `flow accounts fund --network testnet <account>`

## Documentation

- EVM on Flow: https://developers.flow.com/build/evm
- Network details: https://developers.flow.com/build/evm/networks
