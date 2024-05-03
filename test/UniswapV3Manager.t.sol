//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, stdError} from "forge-std/Test.sol";
import "./TestUtils.sol";
import "./ERC20Mintable.sol";
import "../src/UniswapV3Manager.sol";
import "../src/interfaces/IUniswapV3Manager.sol";

contract UniswapV3ManagerTest is Test, TestUtils {
    ERC20Mintable token0;
    ERC20Mintable token1;
    UniswapV3Pool pool;
    UniswapV3Manager manager;

    bool transferInMintCallback = true;
    bool transferInSwapCallback = true;
    bytes extra;

    struct TestCaseParams {
        uint256 wethBalance;
        uint256 usdcBalance;
        uint256 currentPrice;
        IUniswapV3Manager.MintParams[] mints;
        bool transferInMintCallback;
        bool transferInSwapCallback;
        bool mintLiqudity;
    }

    function setUp() public {
        token0 = new ERC20Mintable("Ether", "ETH", 18);
        token1 = new ERC20Mintable("USDC", "USDC", 18);
        manager = new UniswapV3Manager();

        extra = encodeExtra(address(token0), address(token1), address(this));
    }

    function testMintInRange() public {
        IUniswapV3Manager.MintParams[] memory mints = new IUniswapV3Manager.MintParams[](1);
        mints[0] = mintParams(4545, 5500, 1 ether, 5000 ether);
        TestCaseParams memory params = TestCaseParams({
            wethBalance: 1 ether,
            usdcBalance: 5000 ether,
            currentPrice: 5000,
            mints: mints,
            transferInMintCallback: true,
            transferInSwapCallback: true,
            mintLiqudity: true
        });
        (uint256 poolBalance0, uint256 poolBalance1) = setupTestCase(params);

        (uint256 expectedAmount0, uint256 expectedAmount1) = (0.9989955801315816 ether, 4999.999999999999999999 ether);

        assertEq(poolBalance0, expectedAmount0, "incorrect token0 deposited amount");
        assertEq(poolBalance1, expectedAmount1, "incorrect token1 deposited amount");

        assertMintState(
            ExpectedStateAfterMint({
                pool: pool,
                token0: token0,
                token1: token1,
                amount0: expectedAmount0,
                amount1: expectedAmount1,
                lowerTick: mints[0].lowerTick,
                upperTick: mints[0].upperTick,
                positionLiquidity: liquidity(mints[0], 5000),
                currentLiquidity: liquidity(mints[0], 5000),
                sqrtPriceX96: sqrtP(5000),
                tick: tick(5000)
            })
        );
    }

    function mintParams(uint256 lowerPrice, uint256 upperPrice, uint256 amount0, uint256 amount1)
        internal
        pure
        returns (IUniswapV3Manager.MintParams memory params)
    {
        params = IUniswapV3Manager.MintParams({
            poolAddress: address(0x0), // setup in setupTestCase
            lowerTick: tick(lowerPrice),
            upperTick: tick(upperPrice),
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: 0,
            amount1Min: 0
        });
    }

    function liquidity(IUniswapV3Manager.MintParams memory params, uint256 currentPrice)
        internal
        pure
        returns (uint128 liquidity_)
    {
        liquidity_ = LiquidityMath.getLiquidityForAmounts(
            sqrtP(currentPrice),
            TickMath.getSqrtRatioAtTick(params.lowerTick),
            TickMath.getSqrtRatioAtTick(params.upperTick),
            params.amount0Desired,
            params.amount1Desired
        );
    }

    function setupTestCase(TestCaseParams memory params)
        internal
        returns (uint256 poolBalance0, uint256 poolBalance1)
    {
        token0.mint(address(this), params.wethBalance);
        token1.mint(address(this), params.usdcBalance);

        pool =
            new UniswapV3Pool(address(token0), address(token1), sqrtP(params.currentPrice), tick(params.currentPrice));

        if (params.mintLiqudity) {
            token0.approve(address(manager), params.wethBalance);
            token1.approve(address(manager), params.usdcBalance);

            uint256 poolBalance0Tmp;
            uint256 poolBalance1Tmp;

            for (uint256 i = 0; i < params.mints.length; i++) {
                params.mints[i].poolAddress = address(pool);
                (poolBalance0Tmp, poolBalance1Tmp) = manager.mint(params.mints[i]);
                poolBalance0 += poolBalance0Tmp;
                poolBalance1 += poolBalance1Tmp;
            }
        }

        transferInMintCallback = params.transferInMintCallback;
        transferInSwapCallback = params.transferInSwapCallback;
    }
}
