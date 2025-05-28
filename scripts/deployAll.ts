import { ethers } from "ethers";
import dotenv from "dotenv";
import fs from "fs";
import crypto from "crypto";

import { generateZKProof } from "./zkProofGenerator";
import { generateMerkleRoot } from "./merkleRootGenerator";
import amoyBridgeArtifact from "../artifacts/contracts/AmoyBridge.sol/AmoyBridge.json";
import besuBridgeArtifact from "../artifacts/contracts/BesuBridge.sol/BesuBridge.json";

dotenv.config();

function splitNonceHash(nonceHash: string): string[] {
  const cleanHash = nonceHash.startsWith("0x") ? nonceHash.slice(2) : nonceHash;
  const result: string[] = [];
  for (let i = 0; i < cleanHash.length; i += 8) {
    result.push(`0x${cleanHash.slice(i, i + 8)}`);
  }
  return result;
}

function cleanNonceHash(nonceHash: string): string {
  return nonceHash.startsWith("0x") ? nonceHash.slice(2) : nonceHash;
}

function parseValue1AsU32(hexStr: string): number {
  const clean = hexStr.startsWith("0x") ? hexStr.slice(2) : hexStr;
  const last8 = clean.slice(-8);
  return parseInt(last8, 16);
}

async function deployAll() {
  console.log("Deploying contracts...");

  const providerBesu = new ethers.JsonRpcProvider(process.env.BESU_RPC_URL);
  const signerBesu = new ethers.Wallet(process.env.BESU_PRIVATE_KEY!, providerBesu);
  let nonceBesu = await providerBesu.getTransactionCount(signerBesu.address);

  const providerAmoy = new ethers.JsonRpcProvider(process.env.AMOY_RPC_URL);
  const signerAmoy = new ethers.Wallet(process.env.AMOY_PRIVATE_KEY!, providerAmoy);

  const besuTokenFactory = new ethers.ContractFactory(
    (await import("../artifacts/contracts/BesuTraceToken.sol/BesuTraceToken.json")).abi,
    (await import("../artifacts/contracts/BesuTraceToken.sol/BesuTraceToken.json")).bytecode,
    signerBesu
  );
  const besuToken = await besuTokenFactory.deploy({ nonce: nonceBesu++ });
  await besuToken.waitForDeployment();
  const besuTokenAddress = await besuToken.getAddress();
  console.log(`BesuTraceToken deployed at: ${besuTokenAddress}`);

  const besuBridgeFactory = new ethers.ContractFactory(
    (await import("../artifacts/contracts/BesuBridge.sol/BesuBridge.json")).abi,
    (await import("../artifacts/contracts/BesuBridge.sol/BesuBridge.json")).bytecode,
    signerBesu
  );
  const besuBridge = await besuBridgeFactory.deploy(besuTokenAddress, { nonce: nonceBesu++ });
  await besuBridge.waitForDeployment();
  const besuBridgeAddress = await besuBridge.getAddress();
  console.log(`BesuBridge deployed at: ${besuBridgeAddress}`);

  const tokenABI = [
    "function setApprovalForAll(address operator, bool approved) external",
    "function mintTokens(uint256 amount) external"
  ];
  const tokenContract = new ethers.Contract(besuTokenAddress, tokenABI, signerBesu);

  const mintTx = await tokenContract.mintTokens(1000, { nonce: nonceBesu++ });
  await mintTx.wait();
  console.log("Minted 1000 tokens to deployer before approval");

  const approvalTx = await tokenContract.setApprovalForAll(besuBridgeAddress, true, { nonce: nonceBesu++ });
  await approvalTx.wait();
  console.log(`Approval granted to BesuBridge`);

  const amoyTokenFactory = new ethers.ContractFactory(
    (await import("../artifacts/contracts/AmoyTraceToken.sol/AmoyTraceToken.json")).abi,
    (await import("../artifacts/contracts/AmoyTraceToken.sol/AmoyTraceToken.json")).bytecode,
    signerAmoy
  );
  const amoyToken = await amoyTokenFactory.deploy();
  await amoyToken.waitForDeployment();
  const amoyTokenAddress = await amoyToken.getAddress();
  console.log(`AmoyTraceToken deployed at: ${amoyTokenAddress}`);

  //const verifierAddress = "0x296e76F92d474eD61e3aD62dd619ED895C003025";

  const verifierFactory = new ethers.ContractFactory(
    (await import("../artifacts/contracts/Verifier.sol/Verifier.json")).abi,
    (await import("../artifacts/contracts/Verifier.sol/Verifier.json")).bytecode,
    signerAmoy
  );
  const verifier = await verifierFactory.deploy();
  await verifier.waitForDeployment();
  const verifierAddress = await verifier.getAddress();
  console.log("Verifier contract deployed at:", verifierAddress);
  

  const amoyBridgeFactory = new ethers.ContractFactory(
    (await import("../artifacts/contracts/AmoyBridge.sol/AmoyBridge.json")).abi,
    (await import("../artifacts/contracts/AmoyBridge.sol/AmoyBridge.json")).bytecode,
    signerAmoy
  );
  const amoyBridge = await amoyBridgeFactory.deploy(amoyTokenAddress, verifierAddress);
  await amoyBridge.waitForDeployment();
  const amoyBridgeAddress = await amoyBridge.getAddress();
  console.log(`AmoyBridge deployed at: ${amoyBridgeAddress}`);

}

deployAll().catch((error) => {
  console.error("Error in deployment:", error);
  process.exitCode = 1;
});