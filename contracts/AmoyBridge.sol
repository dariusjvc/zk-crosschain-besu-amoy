// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./AmoyTraceToken.sol";
import "./verifier.sol"; // This contract is created by Zokrates

contract AmoyBridge is ERC1155Holder {
    uint256 public constant TRACE_TOKEN_ID = 1;
    AmoyTraceToken public token;
    Verifier public verifierContract; // Reference to verifier.sol
    mapping(bytes32 => bool) public verifiedProofs;

    event Minted(address indexed recipient, uint256 amount);

    constructor(address _token, address _verifier) {
        token = AmoyTraceToken(_token);
        verifierContract = Verifier(_verifier);
    }

    function mintTokens(
        uint256 id,
        uint256 amount,
        uint[9] memory input, 
        Verifier.Proof memory proof, 
        bytes32 zkProofHash
    ) external {
        require(!verifiedProofs[zkProofHash], "Proof already used");

        // Verify zk-SNARK before to continue
        bool verificationResult = verifierContract.verifyTx(proof, input);
        require(verificationResult, "Invalid zk-SNARK proof, assertion failed");

        verifiedProofs[zkProofHash] = true;
        token.mint(msg.sender, id, amount);
        emit Minted(msg.sender, amount);
    }
}
