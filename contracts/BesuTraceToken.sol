// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BesuTraceToken is ERC1155, Ownable {
    uint256 public constant TRACE_TOKEN_ID = 1; // ID para tokens

    event Minted(address indexed minter, uint256 amount);

    constructor() ERC1155("https://besu.example.com/api/metadata/{id}.json") Ownable(msg.sender) {
        _mint(msg.sender, TRACE_TOKEN_ID, 1000000 * 10 ** 18, ""); // Mint inicial
    }

    function mintTokens(uint256 amount) external {
        _mint(msg.sender, TRACE_TOKEN_ID, amount, "");
        emit Minted(msg.sender, amount);
    }
}
