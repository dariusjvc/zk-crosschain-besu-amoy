// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AmoyTraceToken is ERC1155, Ownable {
    uint256 public constant TRACE_TOKEN_ID = 1; // ID para tokens

    event Minted(address indexed minter, uint256 amount);

    constructor() ERC1155("https://amoy.example.com/api/metadata/{id}.json") Ownable(msg.sender) {
    }

    function mint(address recipient, uint256 id, uint256 amount) external {
        _mint(recipient, id, amount, "");
        emit Minted(recipient, amount);
    }
}