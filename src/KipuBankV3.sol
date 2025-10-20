// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IUniversalRouter } from "uniswap/contracts/interfaces/IUniversalRouter.sol";
import { Commands } from "uniswap/contracts/libraries/Commands.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract KipuBankV3 is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant BANK_MANAGER_ROLE = keccak256("BANK_MANAGER_ROLE");

    IUniversalRouter public universalRouter;
    IERC20 public usdc;
    AggregatorV3Interface public ethUsdPriceFeed;

    uint256 public bankCapUSD;
    uint256 public withdrawLimitUSD;
    uint256 public totalDeposited;
    uint256 public depositCount;
    uint256 public withdrawalCount;

    mapping(address => mapping(address => uint256)) public balances;

    event DepositMade(address indexed user, address indexed token, uint256 amount);
    event WithdrawalMade(address indexed user, address indexed token, uint256 amount);

    constructor(
        address _universalRouter,
        address _usdc,
        address _priceFeed,
        uint256 _bankCapUSD,
        uint256 _withdrawLimitUSD
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BANK_MANAGER_ROLE, msg.sender);

        universalRouter = IUniversalRouter(_universalRouter);
        usdc = IERC20(_usdc);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);

        bankCapUSD = _bankCapUSD;
        withdrawLimitUSD = _withdrawLimitUSD;
    }

    receive() external payable {
        depositETH();
    }

    function depositETH() public payable nonReentrant {
        require(msg.value > 0, "Amount must be greater than zero");

        uint256 beforeBalance = usdc.balanceOf(address(this));

        // Command: [SWAP_EXACT_IN]
        bytes memory commands = abi.encodePacked(Commands.V3_SWAP_EXACT_IN);

        // Payload: swap ETH -> USDC
        bytes memory swapData = abi.encode(
            address(0),            // tokenIn (ETH)
            address(usdc),         // tokenOut
            address(this),         // recipient
            true,                  // unwrap ETH flag (true for ETH input)
            msg.value,             // amountIn
            1                      // amountOutMinimum (use oracle in production)
        );

        bytes[] memory inputs = new bytes[](1);
        inputs[0] = swapData;

        // Perform swap using msg.value
        universalRouter.execute{value: msg.value}(commands, inputs, block.timestamp + 300);

        uint256 afterBalance = usdc.balanceOf(address(this));
        uint256 usdcReceived = afterBalance - beforeBalance;

        require(totalDeposited + usdcReceived <= bankCapUSD, "Bank cap exceeded");

        balances[msg.sender][address(usdc)] += usdcReceived;
        totalDeposited += usdcReceived;
        depositCount++;

        emit DepositMade(msg.sender, address(usdc), usdcReceived);
    }

    function depositArbitraryToken(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(token != address(0), "Use depositETH for native");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeApprove(address(universalRouter), amount);

        uint256 usdcReceived = _swapExactInputSingle(token, address(usdc), amount);
        require(totalDeposited + usdcReceived <= bankCapUSD, "Bank cap exceeded");

        balances[msg.sender][address(usdc)] += usdcReceived;
        totalDeposited += usdcReceived;
        depositCount++;

        emit DepositMade(msg.sender, address(usdc), usdcReceived);
    }

    function _swapExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        uint256 beforeBalance = IERC20(tokenOut).balanceOf(address(this));

        bytes memory commands = abi.encodePacked(
            Commands.PERMIT2_TRANSFER_FROM,
            Commands.V3_SWAP_EXACT_IN
        );

        bytes memory transferFromData = abi.encode(
            msg.sender,
            address(this),
            tokenIn,
            amountIn
        );

        bytes memory swapData = abi.encode(
            tokenIn,
            tokenOut,
            address(this),
            false,
            amountIn,
            1 // Minimum output; adjust for slippage tolerance
        );

        bytes[] memory inputs = new bytes[](2);
        inputs[0] = transferFromData;
        inputs[1] = swapData;

        universalRouter.execute(commands, inputs, block.timestamp + 300);

        uint256 afterBalance = IERC20(tokenOut).balanceOf(address(this));
        amountOut = afterBalance - beforeBalance;
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender][address(usdc)] >= amount, "Insufficient balance");
        require(amount <= withdrawLimitUSD, "Exceeds withdrawal limit");

        balances[msg.sender][address(usdc)] -= amount;
        totalDeposited -= amount;
        withdrawalCount++;

        usdc.safeTransfer(msg.sender, amount);
        emit WithdrawalMade(msg.sender, address(usdc), amount);
    }

    function getVaultBalance(address user) external view returns (uint256) {
        return balances[user][address(usdc)];
    }

    function getLatestETHPrice() public view returns (int256) {
        (, int256 price,,,) = ethUsdPriceFeed.latestRoundData();
        return price;
    }
}
