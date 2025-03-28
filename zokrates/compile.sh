#!/bin/bash

ZOKRATES_DIR="$(dirname "$0")"  # Get the directory where the script is located

echo "Compiling ZoKrates circuit..."
zokrates compile -i "$ZOKRATES_DIR/circuits/lock_proof.zok" -o "$ZOKRATES_DIR/artifacts/lock_proof"

echo "Setting up ZoKrates proving and verification keys..."
zokrates setup -i "$ZOKRATES_DIR/artifacts/lock_proof" -p "$ZOKRATES_DIR/artifacts/proving.key" -v "$ZOKRATES_DIR/artifacts/verification.key"

# Check if verification key file is not empty
if [ ! -s "$ZOKRATES_DIR/artifacts/verification.key" ]; then
    echo "Error: verification.key file is empty or not found."
    exit 1
fi

echo "Exporting Solidity verifier..."
#echo "$ZOKRATES_DIR/artifacts/verification.key"
#cat "$ZOKRATES_DIR/artifacts/verification.key"
zokrates export-verifier -i "$ZOKRATES_DIR/artifacts/verification.key" -o "$ZOKRATES_DIR/artifacts/verifier.sol"

echo "Compilation completed successfully!"
