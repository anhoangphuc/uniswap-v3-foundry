//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "./TestUtils.sol";
import "./ERC20Mintable.sol";

import "../src/UniswapV3Pool.sol";
import "../src/UniswapV3Manager.sol";
import "../src/UniswapV3Quoter.sol";
import "../src/interfaces/IUniswapV3Manager.sol";

contract UniswapV3QuoterTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;
    UniswapV3Manager manager;
    UniswapV3Quoter quoter;

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);

        uint256 wethBalance = 100 ether;
        uint256 usdcBalance = 1000000 ether;

        token0.mint(address(this), wethBalance);
        token1.mint(address(this), usdcBalance);

        pool = new UniswapV3Pool(address(token0), address(token1), sqrtP(5000), tick(5000));

        manager = new UniswapV3Manager();

        token0.approve(address(manager), wethBalance);
        token1.approve(address(manager), usdcBalance);

        manager.mint(
            IUniswapV3Manager.MintParams({
                poolAddress: address(pool),
                lowerTick: tick(4545),
                upperTick: tick(5500),
                amount0Desired: 1 ether,
                amount1Desired: 5000 ether,
                amount0Min: 0,
                amount1Min: 0
            })
        );

        quoter = new UniswapV3Quoter();
    }

    function testQuoteUSDCforETH() public {
        (uint256 amountOut, uint160 sqrtPriceX96After, int24 tickAfter) = quoter.quote(
            UniswapV3Quoter.QuoteParams({
                pool: address(pool),
                amountIn: 0.01337 ether,
                sqrtPriceLimitX96: sqrtP(4993),
                zeroForOne: true
            })
        );

        assertEq(amountOut, 66.807123823853842027 ether, "invalid amountOut");
        assertEq(sqrtPriceX96After, 5598737223630966236662554421688, "invalid sqrtPriceX96After");
        assertEq(tickAfter, 85163, "invalid tickAFter");
    }
}
