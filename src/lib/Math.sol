// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

library Math {
    function calcAmount0Delta(uint160 sqrtPriceAX96, uint160 sqrtPriceBX96, uint128 liquidity)
        internal
        pure
        returns (uint256 amount0)
    {
        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }

        require(sqrtPriceAX96 > 0);
    }
}
