import { ethers } from "hardhat";
import { expect } from "chai";
import fs from "fs"; // To read proof.json

describe("AmoyBridge Performance Test", function () {
  let amoyBridge: any, token: any;
  let owner: any, user: any;

  before(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy token contract
    const Token = await ethers.getContractFactory("AmoyTraceToken");
    token = await Token.deploy();
    await token.waitForDeployment();

    // Deploy verifier contract
    const Verifier = await ethers.getContractFactory("Verifier");
    const verifier = await Verifier.deploy();
    await verifier.waitForDeployment();

    // Deploy bridge contract
    const AmoyBridge = await ethers.getContractFactory("AmoyBridge");
    amoyBridge = await AmoyBridge.deploy(await token.getAddress(), await verifier.getAddress());
    await amoyBridge.waitForDeployment();
  });

  it("Should measure gas and execution time for mintTokens (including verifyTx)", async function () {
    // Read `proof.json`
    const proofData = JSON.parse(fs.readFileSync("proof.json", "utf8"));

    const proof = {
      a: proofData.proof.a.map((x: string) => BigInt(x)),
      b: proofData.proof.b.map((pair: string[]) => pair.map((x: string) => BigInt(x))),
      c: proofData.proof.c.map((x: string) => BigInt(x))
    };
    const inputs = proofData.inputs.map((x: string) => BigInt(x));

    const zkProofHash = ethers.keccak256(ethers.toUtf8Bytes("dummy"));

    try {
      // ⏱️ Measure execution time and gas of `mintTokens`
      const start = Date.now();
      const tx = await amoyBridge.mintTokens(1, 100, inputs, proof, zkProofHash);
      const receipt = await tx.wait();
      const end = Date.now();

      console.log(` Total execution time (mintTokens including verifyTx): ${end - start} ms`);
      console.log(` Total gas used: ${receipt.gasUsed.toString()}`);

      // Fetch the gas price manually
      const feeData = await ethers.provider.getFeeData();
const gasPrice = feeData.gasPrice; // 

      // 💰 Calculate transaction fee in ETH
      const gasUsed = BigInt(receipt.gasUsed.toString());
      const txFeeWei = gasUsed * gasPrice;
      const txFeeEth = ethers.formatUnits(txFeeWei, "ether");

      console.log(`Tx Fee: ${txFeeEth} ETH`);

      expect(receipt.status).to.equal(1);
    } catch (error: any) {
      console.error("Transaction failed:", error.reason || error);
    }
  });
});
