//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./TestUtils.sol";
import "./ERC20Mintable.sol";

import "../src/UniswapV3Pool.sol";
import "../src/UniswapV3Manager.sol";
import "../src/UniswapV3Quoter.sol";
import "../src/UniswapV3Factory.sol";
import "../src/interfaces/IUniswapV3Manager.sol";

contract UniswapV3QuoterTest is Test, TestUtils {
    ERC20Mintable weth;
    ERC20Mintable usdc;
    ERC20Mintable uni;
    UniswapV3Pool wethUSDC;
    UniswapV3Pool wethUNI;
    UniswapV3Manager manager;
    UniswapV3Quoter quoter;
    UniswapV3Factory factory;

    function setUp() public {
        usdc = new ERC20Mintable("USDC", "USDC", 18);
        weth = new ERC20Mintable("Ether", "ETH", 18);
        uni = new ERC20Mintable("Uniswap Coin", "UNI", 18);
        factory = new UniswapV3Factory();

        uint256 wethBalance = 100 ether;
        uint256 usdcBalance = 1000000 ether;
        uint256 uniBalance = 1000 ether;

        weth.mint(address(this), wethBalance);
        usdc.mint(address(this), usdcBalance);
        uni.mint(address(this), uniBalance);

        wethUSDC = deployPool(factory, address(weth), address(usdc), 60, 5000);
        wethUNI = deployPool(factory, address(weth), address(uni), 60, 10);

        manager = new UniswapV3Manager(address(factory));

        weth.approve(address(manager), wethBalance);
        usdc.approve(address(manager), usdcBalance);
        uni.approve(address(manager), uniBalance);

        manager.mint(
            IUniswapV3Manager.MintParams({
                tokenA: address(weth),
                tokenB: address(usdc),
                tickSpacing: 60,
                lowerTick: tick60(4545),
                upperTick: tick60(5500),
                amount0Desired: 1 ether,
                amount1Desired: 5000 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        manager.mint(
            IUniswapV3Manager.MintParams({
                tokenA: address(weth),
                tokenB: address(uni),
                tickSpacing: 60,
                lowerTick: tick60(7),
                upperTick: tick60(13),
                amount0Desired: 10 ether,
                amount1Desired: 100 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        quoter = new UniswapV3Quoter(address(factory));
    }

    function testQuoteUSDCforETH() public {
        (uint256 amountOut, uint160 sqrtPriceX96After, int24 tickAfter) = quoter.quoteSingle(
            UniswapV3Quoter.QuoteSingleParams({
                tokenIn: address(weth),
                tokenOut: address(usdc),
                tickSpacing: 60,
                amountIn: 0.01337 ether,
                sqrtPriceLimitX96: sqrtP(4993)
            })
        );
        assertEq(amountOut, 66.809153442256308009 ether, "invalid amountOut");
        assertEq(
            sqrtPriceX96After,
            5598854004958668990019104567840, // 4993.891686050662
            "invalid sqrtPriceX96After"
        );
        assertEq(tickAfter, 85163, "invalid tickAFter");
    }
}
