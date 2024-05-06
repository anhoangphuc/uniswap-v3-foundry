// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

interface IUniswapV3PoolDeployer {
    struct PoolParameters {
        address factory;
        address token0;
        address token1;
        uint24 tickSpacing;
    }

    function parameters() external returns (address factory, address token0, address token1, uint24 tickSpacing);
}
