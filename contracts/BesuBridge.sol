// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BesuBridge is ERC1155Holder, Ownable {
    IERC1155 public token;
    uint256 public constant TRACE_TOKEN_ID = 1;
    uint256 private nonceCounter;

    event Locked(bytes encryptedData, uint256 blockNumber, uint256 timestamp, bytes32 uniqueEventHash);

    constructor(address _token) Ownable(msg.sender) {
        token = IERC1155(_token);
    }

    function lockTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        

        token.safeTransferFrom(msg.sender, address(this), TRACE_TOKEN_ID, amount, "");

        string memory formatted = _formatData(amount, TRACE_TOKEN_ID);

        bytes memory encryptedBytes = _encryptData(formatted);

        nonceCounter++;
        bytes32 uniqueEventHash = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp, nonceCounter));

        emit Locked(encryptedBytes, block.number, block.timestamp, uniqueEventHash);
    }

    function _formatData(uint256 amount, uint256 id) internal pure returns (string memory) {
        string memory amountStr = _padLeft(amount, 5);
        string memory idStr = _padLeft(id, 5);
        return string(abi.encodePacked(idStr, amountStr)); 
    }

    function _padLeft(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory str = bytes(_uintToString(value));
        if (str.length >= length) return string(str);

        bytes memory padded = new bytes(length);
        uint256 offset = length - str.length;
        for (uint256 i = 0; i < offset; i++) {
            padded[i] = "0";
        }
        for (uint256 i = 0; i < str.length; i++) {
            padded[offset + i] = str[i];
        }
        return string(padded);
    }

    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _encryptData(string memory data) internal view returns (bytes memory) {
        bytes memory dataBytes = bytes(data);
        bytes memory encrypted = new bytes(dataBytes.length);
        bytes32 secretKey = keccak256(abi.encodePacked(owner()));

        for (uint256 i = 0; i < dataBytes.length; i++) {
            encrypted[i] = dataBytes[i] ^ secretKey[i % 32];
        }

        return encrypted;
    }
}