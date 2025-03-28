import { ethers } from "hardhat";
import * as Ethers from "ethers";
import dotenv from "dotenv";
import fs from "fs";
import { generateZKProof } from "./zkProofGenerator";
import { generateMerkleRoot } from "./merkleRootGenerator";
import crypto from "crypto";

import amoyBridgeArtifact from "../artifacts/contracts/AmoyBridge.sol/AmoyBridge.json";
import besuBridgeArtifact from "../artifacts/contracts/BesuBridge.sol/BesuBridge.json"

dotenv.config();

function splitNonceHash(nonceHash: string): string[] {
  // Delete the  "0x" if it's present
  const cleanHash = nonceHash.startsWith("0x") ? nonceHash.slice(2) : nonceHash;

  // Divide in 8 characters
  const result: string[] = [];
  for (let i = 0; i < cleanHash.length; i += 8) {
    result.push(`0x${cleanHash.slice(i, i + 8)}`);
  }

  return result;
}

function cleanBigInt(value: bigint): number | string {
  return value <= Number.MAX_SAFE_INTEGER ? Number(value) : value.toString();
}


function cleanNonceHash(nonceHash: string): string {
  return nonceHash.startsWith("0x") ? nonceHash.slice(2) : nonceHash;
}

// Besu Connection
const providerBesu = new ethers.JsonRpcProvider(process.env.BESU_RPC_URL);
const signerBesu = new ethers.Wallet(process.env.BESU_PRIVATE_KEY!, providerBesu);

const besuBridgeABI = besuBridgeArtifact.abi;

const besuBridgeAddress = "<BESU_BRIDGE_ADDRESS_HERE>";
const besuBridge = new ethers.Contract(besuBridgeAddress, besuBridgeABI, signerBesu);

// Amoy Connection
const amoyProvider = new ethers.JsonRpcProvider(process.env.AMOY_RPC_URL);
const signerAmoy = new ethers.Wallet(process.env.AMOY_PRIVATE_KEY!, amoyProvider);
const amoyBridgeAddress = "AMOY_BRIDGE_ADDRESS_HERE";

const amoyBridgeABI = amoyBridgeArtifact.abi;
const amoyBridge = new ethers.Contract(amoyBridgeAddress, amoyBridgeABI, signerAmoy);


// Listen for lock events on Besu
console.log("Listening to besu lock events");

besuBridge.on("Locked", async (encryptedData, blockNumber, timestamp, nonceHash) => {

  const blockNumberN = Number(blockNumber);
  const encryptedDataN = parseValue1AsU32(encryptedData);

  const timestampNumber = Number(timestamp);

  const startTime = Date.now();

  const nonceHashArray = splitNonceHash(nonceHash);

  const merkleRootTets = generateMerkleRoot(encryptedData, blockNumberN, timestampNumber, cleanNonceHash(nonceHash));

  // Generate the zk-Proof with the computed merkleRoot.
  const proofFile = generateZKProof(
    encryptedDataN,
    blockNumberN,
    timestampNumber,
    nonceHashArray,
    merkleRootTets
  );

  fs.readFile(proofFile, 'utf8', async (err, data) => {
    if (err) {
      console.error('Error reading file:', err);
      return;
    }
    try {
      const jsonData = JSON.parse(data);

      // Generate the hash256 of the proof
      const hashProof = crypto.createHash("sha256").update(JSON.stringify(jsonData)).digest();
      const zkProofHash = "0x" + hashProof.toString("hex");

      console.log(`zkProofHash: ${zkProofHash}`);

      const proof = [
        jsonData.proof.a,
        jsonData.proof.b,
        jsonData.proof.c
      ];
      const inputs = jsonData.inputs;

      try {
        const beforeMintTime = Date.now();

        const tx = await amoyBridge.mintTokens(encryptedData, inputs, proof, zkProofHash);
        await tx.wait();

        const endTime = Date.now();

        console.log(`mint tx: ${tx.hash}`);

        const totalProcessingTimeMs = endTime - startTime;
        const zkProofGenerationTimeMs = beforeMintTime - startTime;
        const mintExecutionTimeMs = endTime - beforeMintTime;

        console.log(`Total processing time: ${totalProcessingTimeMs} ms`);
        console.log(`ZK-Proof generation time: ${zkProofGenerationTimeMs} ms`);
        console.log(`Mint execution time: ${mintExecutionTimeMs} ms`);

      } catch (error) {
        console.error('Error minting token:', error);
      }
    } catch (parseError) {
      console.error('Error parsing JSON:', parseError);
    }
  });
});


function parseValue1AsU32(hexStr: string): number {
  const clean = hexStr.startsWith("0x") ? hexStr.slice(2) : hexStr;
  const last8 = clean.slice(-8);
  return parseInt(last8, 16);
}