import { execSync } from "child_process";
import path from "path";
import fs from "fs";

const zokratesDir = path.join(__dirname, "../zokrates");

// BN128 field modulus used in ZoKrates (BN128 curve)
const FIELD_MODULUS = BigInt("21888242871839275222246405745257275088548364400416034343698204186575808495617");

export function generateZKProof(
  encryptedData: number,
  blockNumber: number,
  timestamp: number,
  nonceHash: string [],
  merkleRoot: string []
): string {
  try {
    console.log("Generating zk-Proof using ZoKrates...");

    const merkleRootDecimals = merkleRoot.map(h => BigInt(h).toString());
    const nonceHashDecimals = nonceHash.map(h => BigInt(h).toString());
    execSync(
      `zokrates compute-witness -i ${zokratesDir}/artifacts/lock_proof -a ${encryptedData} ${blockNumber} ${timestamp} ${nonceHashDecimals.join(" ")} ${merkleRootDecimals.join(" ")}`,
      { stdio: "inherit" }
    );


    execSync(
      `zokrates generate-proof --input ${zokratesDir}/artifacts/lock_proof --proving-key-path ${zokratesDir}/artifacts/proving.key > ${zokratesDir}/artifacts/proof.json`,
      { stdio: "inherit" }
    );

    console.log("zk-Proof successfully generated.");

    // Verificar que el archivo de prueba se creó correctamente
    const proofFile = `proof.json`;
    if (!fs.existsSync(proofFile)) {
      throw new Error("Proof file not found!");
    }

    return proofFile;
  } catch (error) {
    console.error("Error generating zk-Proof:", error);
    throw error;
    
  }
}
