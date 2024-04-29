//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface IUniswapV3Pool {
    function slot0() external view returns (uint160 sqrtPriceX96, int24 tick);

    function swap(address recipient, bool zeroForOne, uint256 amountSpecified, bytes calldata data)
        external
        returns (int256, int256);
}
