# zk-crosschain-besu-amoy

This project is a **Proof of Concept (PoC)** for the research paper [_"Bridging Private & Public Blockchains: A zkSNARK Framework for Secure ERC-1155 Transfers"_](https://www.researchgate.net/publication/393057046_Bridging_Private_and_Public_Blockchains_A_zk-SNARK_Framework_for_Secure_ERC-1155_Transfers).

It demonstrates how **zero-knowledge proofs** can be used to securely bridge token transfers between a **private Hyperledger Besu network** and the **public Amoy testnet** using **zk-SNARKs**, **Merkle trees**, and **ERC-1155** tokens.

---

## Requirements

- `node v20.18.2`
- `ZoKrates v0.8.8`
- Docker (for running Besu)
- A wallet with ETH on Amoy testnet (e.g. via [Polygon Faucet](https://faucet.polygon.technology/))

---

## Setup & Deployment

### 1. Environment Variables

Create a `.env` file in the root directory with the following values:

```env
BESU_RPC_URL=http://127.0.0.1:8545
BESU_PRIVATE_KEY=<YOUR_BESU_PRIVATE_KEY>

AMOY_RPC_URL=<YOUR_AMOY_RPC_URL>
AMOY_PRIVATE_KEY=<YOUR_AMOY_PRIVATE_KEY>
```

>_The same private key/account must be used on both Besu and Amoy._

>_Amoy Faucet: You can request test POLs (Polygon tokens) for your Amoy account from the Amoy Faucet to ensure you have sufficient funds to deploy and interact with contracts._

---

### 2. Run Besu (Private Chain)

You can run a local private Hyperledger Besu network using the official guide:

```shell
https://besu.hyperledger.org/24.7.1/private-networks/tutorials/quickstart
```

---

### 3. Compile zk-SNARK Circuit

Compile the circuit and generate the Verifier smart contract using ZoKrates:

```bash
zokrates/compile.sh
```

Then **copy the generated `verifier.sol`** file to your `contracts/` directory.

---

### 4. Deploy Smart Contracts

To deploy **BesuBridge**, **BesuTraceToken**, **AmoyBridge**, **AmoyTraceToken**, and **Verifier**, run:
```bash
npm install
```
```bash
npx hardhat compile
```
```bash
npx ts-node scripts/deployAll.ts
```

This will:
- Deploy contracts on both chains
- Mint test tokens
- Approve bridges
- Print deployed addresses

---

### 5. Run Relayer

Update the `relayer.ts` file with the printed `besuBridgeAddress` and `amoyBridgeAddress` from the deploy step. Then run:

```bash
npx hardhat run scripts/relayer.ts
```

This script listens to lock events on Besu and relays zk-proofs to Amoy.

---

### 6. Trigger a Lock Event (Besu)
Update the `besuBridgeAddress`.

To simulate token locking in Besu, open a new terminal and execute:

```bash
npx hardhat run scripts/lockTokens.ts --network besu
```

---

### Tests

To run tests (e.g. on `AmoyBridge`), use:

```bash
npx hardhat test test/AmoyBridge.ts --network amoy
```

---

## Conclusion

This PoC successfully showcases a working model for **secure and scalable cross-chain token transfers** using zk-SNARKs between a **private Besu chain** and a **public Amoy testnet**. It demonstrates the potential of privacy-preserving protocols for real-world blockchain interoperability.

---
