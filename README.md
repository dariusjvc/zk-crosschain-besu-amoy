# zk-crosschain-besu-amoy
This project is a Proof of Concept (PoC) for the paper "Bridging Private and Public Blockchains: A zk-SNARK-Based Cross-Chain Framework for Secure ERC-1155 Transfers." 

## Requirements

node v20.18.2
ZoKrates 0.8.8 

## How to deploy

### .env
Create .env and put variables:

```shell
BESU_RPC_URL=http://127.0.0.1:8545
BESU_PRIVATE_KEY=<YOUR_BESU_PRIVATE_KEY>

AMOY_RPC_URL=<YOUR_AMOY_RPC_HERE>
AMOY_PRIVATE_KEY=<YOUR_BESU_PRIVATE_KEY>
```

Important to note that we are using the same account in Besu and Amoy!

### Smart Contracts

### Relayer
```shell
npx hardhat run scripts/relayer.ts;
```

### Lock Event

```shell
npx hardhat run scripts/lockTokens.ts --network besu;
```

## Tests

```shell
npx hardhat test test/AmoyBridge.ts --network amoy
```

## Conclusion

The implementation of zk-SNARK-based cross-chain transfers has demonstrated its feasibility for secure and scalable token migration between private (Hy-perledger Besu) and public (Amoy) blockchain networks

