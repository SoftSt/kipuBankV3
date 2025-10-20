// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/KipuBankV3.sol";
import "../src/mocks/MockUSDC.sol";
import "../src/mocks/MockAggregator.sol";
import "../src/mocks/MockUniversalRouter.sol";

contract KipuBankV3Test is Test {
    KipuBankV3 public bank;
    MockUSDC public usdc;
    MockAggregator public priceFeed;
    MockUniversalRouter public universalRouter;

    address public user = address(1);

    function setUp() public {
        // Deploy mocks
        usdc = new MockUSDC();
        priceFeed = new MockAggregator(1500e8, 8); // ETH/USD = 1500, 8 decimals
        universalRouter = new MockUniversalRouter(address(usdc));

        // Send USDC to universalRouter so it can simulate a swap
        usdc.transfer(address(universalRouter), 100_000e6);

        // Deal user some ETH
        vm.deal(user, 100 ether);

        // Deploy the bank contract
        bank = new KipuBankV3(
            address(universalRouter),
            address(usdc),
            address(priceFeed),
            1_000_000e6,
            100_000e6
        );
    }

    function testDeployment() public {
        assertEq(address(bank.universalRouter()), address(universalRouter));
        assertEq(address(bank.usdc()), address(usdc));
        assertEq(address(bank.ethUsdPriceFeed()), address(priceFeed));
    }

function testDepositETHEmitsEvent() public {
    uint256 expectedAmount = 1500e6; // 1 ETH * 1500 USD = 1500 USDC

    // Simula que el swap ya sucedió transfiriendo el USDC directamente al contrato
    usdc.transfer(address(bank), expectedAmount);

    vm.prank(user);
    vm.expectEmit(true, true, true, true);
    emit DepositMade(user, address(usdc), expectedAmount);

    bank.depositETH{value: 1 ether}();
}

    event DepositMade(address indexed user, address indexed token, uint256 amount);
}
