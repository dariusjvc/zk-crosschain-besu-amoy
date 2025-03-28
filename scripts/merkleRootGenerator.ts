import crypto from "crypto";

// Función para calcular SHA-256
function sha256(data: Buffer): Buffer {
  return crypto.createHash("sha256").update(data).digest();
}

// Función para convertir un número en un Buffer de 4 bytes (big-endian)
function uint32ToBuffer(value: number): Buffer {
  const buffer = Buffer.alloc(4);
  buffer.writeUInt32BE(value, 0);
  return buffer;
}

// Función para convertir un BigInt en Buffer big-endian dinámico
function bigIntToBuffer(value: BigInt): Buffer {
  let hex = value.toString(16);
  if (hex.length % 2) hex = "0" + hex; // padding si longitud impar
  return Buffer.from(hex, "hex");
}

// Función para dividir un hash SHA-256 en 8 partes de 4 bytes (uint32)
export function splitHashIntoUint32Array(hash: Buffer): string[] {
  const result: string[] = [];
  for (let i = 0; i < 32; i += 4) {
    result.push(`0x${hash.readUInt32BE(i).toString(16).padStart(8, "0")}`);
  }
  return result;
}
function parseValue1AsU32(hexStr: string): number {
  // Extraer los últimos 8 caracteres del string (32 bits)
  const clean = hexStr.startsWith("0x") ? hexStr.slice(2) : hexStr;
  const last8 = clean.slice(-8);
  return parseInt(last8, 16);
}
// Función para calcular el Merkle Root
export function generateMerkleRoot(
  value1: string,   // hex grande, pero solo tomaremos los últimos 32 bits
  value2: number,
  value3: number,
  nonceHash: string
): string[] {
  // We use only the last 4 bytes from value 1 (Future improvement)
  const value1AsU32 = parseValue1AsU32(value1);

  const hash1 = sha256(uint32ToBuffer(value1AsU32));

  const hash2 = sha256(uint32ToBuffer(value2));

  const [sortedHash1, sortedHash2] =
    hash1.toString("hex") < hash2.toString("hex") ? [hash1, hash2] : [hash2, hash1];

  const hashA = sha256(Buffer.concat([sortedHash1, sortedHash2]));
  //console.log(`HashA: ${hashA.toString("hex")}`);

  const nonceBuffer = Buffer.from(nonceHash, "hex");
  const hashedNonce = sha256(nonceBuffer);
  //console.log("NonceHash (hashed):", splitHashIntoUint32Array(hashedNonce));

  const hash3 = sha256(uint32ToBuffer(value3));

  const [sortedHash3, sortedNonce] =
    hash3.toString("hex") < hashedNonce.toString("hex") ? [hash3, hashedNonce] : [hashedNonce, hash3];

  const hashB = sha256(Buffer.concat([sortedHash3, sortedNonce]));
  //console.log(`HashB: ${hashB.toString("hex")}`);

  const [sortedHashA, sortedHashB] =
    hashA.toString("hex") < hashB.toString("hex") ? [hashA, hashB] : [hashB, hashA];

  const merkleRoot = sha256(Buffer.concat([sortedHashA, sortedHashB]));
  //console.log(`Merkle Root: ${merkleRoot.toString("hex")}`);
  //console.log(splitHashIntoUint32Array(merkleRoot));

  return splitHashIntoUint32Array(merkleRoot);
}

function splitNonceHash(nonceHash: string): string[] {
  // Delete the `0x´ if it's present
  const cleanHash = nonceHash.startsWith("0x") ? nonceHash.slice(2) : nonceHash;

  // Divide the hash in 8 characters (every one represents 4 bytes)
  const result: string[] = [];
  for (let i = 0; i < cleanHash.length; i += 8) {
    result.push(`0x${cleanHash.slice(i, i + 8)}`);
  }

  return result;
}

//generateMerkleRoot( "0x690184dd639cd4f45b59",  5000, 1700000000, "47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a");