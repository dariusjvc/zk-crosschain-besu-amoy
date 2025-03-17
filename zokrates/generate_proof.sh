#!/bin/bash

cd "$(dirname "$0")"

# Check that exactly 2 arguments are provided: timestamp and merkleRoot
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <timestamp> <merkleRoot>"
  exit 1
fi

# Field modulus for ZoKrates (BN128)
FIELD_MODULUS=21888242871839275222246405745257275088548364400416034343698204186575808495617

# Reduce the provided merkleRoot modulo the field modulus and remove extra characters.
merkleInput="$2"
merkleReduced=$(echo "$merkleInput % $FIELD_MODULUS" | bc | tr -d '\n' | tr -d ' ' | tr -d '\\')

echo "Using reduced merkleRoot: $merkleReduced"

# Calculate witness using timestamp and merkleRoot
zokrates compute-witness -i artifacts/lock_proof -a "$1" "$merkleReduced"

# Generate the proof using the new CLI syntax
zokrates generate-proof --input artifacts/lock_proof --proving-key-path artifacts/proving.key > artifacts/proof.json

echo "zk-Proof generated successfully."
