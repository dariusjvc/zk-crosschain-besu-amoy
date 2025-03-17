// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract BesuBridge is ERC1155Holder {
    IERC1155 public token;
    uint256 public constant TRACE_TOKEN_ID = 1;
    uint256 private nonceCounter;

    event Locked(uint256 amount, uint256 id, uint256 timestamp, bytes32 uniqueEventHash);

    constructor(address _token) {
        token = IERC1155(_token);
    }

    function lockTokens(uint256 amount) external  {
        require(amount > 0, "Amount must be greater than 0");

        // Transfer tokens to this contract
        token.safeTransferFrom(msg.sender, address(this), TRACE_TOKEN_ID, amount, "");

        // Increment the nonce in order to get an unique lock event
        nonceCounter++;

        // Generate a uniqueEventHash
        bytes32 uniqueEventHash = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp, nonceCounter));

        // Emit event with uniqueEventHash 
        emit Locked( amount, TRACE_TOKEN_ID, block.timestamp, uniqueEventHash);
    }
}
