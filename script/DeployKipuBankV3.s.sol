// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/KipuBankV3.sol";
import "../src/mocks/MockUniversalRouter.sol";

contract DeployKipuBankV3 is Script {
    function run() external {
        // Load environment variables
        address usdc = vm.envAddress("USDC_ADDRESS");
        address priceFeed = vm.envAddress("CHAINLINK_FEED");

        uint256 bankCapUSD = 1_000_000e6;
        uint256 withdrawLimitUSD = 100_000e6;

        vm.startBroadcast();

        // 1. Deploy the mock universal router
        MockUniversalRouter mockRouter = new MockUniversalRouter(usdc);

        // 2. Deploy KipuBankV3 using the mock as router
        KipuBankV3 kipu = new KipuBankV3(
            address(mockRouter),
            usdc,
            priceFeed,
            bankCapUSD,
            withdrawLimitUSD
        );

        vm.stopBroadcast();
    }
}
