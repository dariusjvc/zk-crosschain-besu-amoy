import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./AmoyTraceToken.sol";
import "./verifier.sol"; // Importamos el contrato Verifier

contract AmoyBridge is ERC1155Holder, Ownable {
    uint256 public constant TRACE_TOKEN_ID = 1;
    AmoyTraceToken public token;
    Verifier public verifierContract;
    mapping(bytes32 => bool) public verifiedProofs;

    event Minted(address indexed recipient, uint256 amount);

    constructor(address _token, address _verifier) Ownable(msg.sender) {
        token = AmoyTraceToken(_token);
        verifierContract = Verifier(_verifier);
    }

    function mintTokens(
        bytes memory encryptedData,
        uint[9] memory input,
        Verifier.Proof memory proof,
        bytes32 zkProofHash
    ) external {
        require(!verifiedProofs[zkProofHash], "Proof already used");

        string memory decryptedString = _decryptData(encryptedData);
        (uint256 id, uint256 amount) = _parseDecryptedString(decryptedString);

        bool verificationResult = verifierContract.verifyTx(proof, input);
        require(verificationResult, "Invalid zk-SNARK proof, assertion failed");

        verifiedProofs[zkProofHash] = true;
        token.mint(msg.sender, id, amount);

        emit Minted(msg.sender, amount);
    }

    function _decryptData(bytes memory encryptedData) internal view returns (string memory) {
        bytes memory decrypted = new bytes(encryptedData.length);
        bytes32 secretKey = keccak256(abi.encodePacked(owner()));

        for (uint256 i = 0; i < encryptedData.length; i++) {
            decrypted[i] = encryptedData[i] ^ secretKey[i % 32];
        }

        return string(decrypted);
    }

    function _parseDecryptedString(string memory data) internal pure returns (uint256, uint256) {
        bytes memory dataBytes = bytes(data);
        require(dataBytes.length >= 10, "Decrypted data must be at least 10 characters");

        bytes memory idBytes = _slice(dataBytes, 0, 5);
        bytes memory amountBytes = _slice(dataBytes, 5, 5);

        uint256 id = _parseUint(string(idBytes));
        uint256 amount = _parseUint(string(amountBytes));

        return (id, amount);
    }

    function _slice(bytes memory data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        require(start + length <= data.length, "Slice out of bounds");

        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[start + i];
        }
        return result;
    }

    function _parseUint(string memory s) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        for (uint i = 0; i < b.length; i++) {
            require(b[i] >= 0x30 && b[i] <= 0x39, "Invalid character in number");
            result = result * 10 + (uint8(b[i]) - 48);
        }
    }
}