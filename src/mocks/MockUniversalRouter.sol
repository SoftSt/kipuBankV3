// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../mocks/MockUSDC.sol"; // Asegúrate de importar correctamente

contract MockUniversalRouter {
    address public usdc;

    constructor(address _usdc) {
        usdc = _usdc;
    }

    receive() external payable {}

    function execute(
        bytes memory,
        bytes[] memory,
        uint256
    ) external payable {
        // Simula el swap: transfiere 1500e6 USDC al que llama (el banco)
        MockUSDC(usdc).transfer(msg.sender, 1500e6);
    }
}
