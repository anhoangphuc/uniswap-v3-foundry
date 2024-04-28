// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./FixedPoint96.sol";
import "prb-math/Common.sol";

library Math {
    /// @notice Calculates amount0 delta between two prices
    /// TODO: round down when removing liquidity
    function calcAmount0Delta(uint160 sqrtPriceAX96, uint160 sqrtPriceBX96, uint128 liquidity)
        internal
        pure
        returns (uint256 amount0)
    {
        if (sqrtPriceAX96 > sqrtPriceBX96) {
            (sqrtPriceAX96, sqrtPriceBX96) = (sqrtPriceBX96, sqrtPriceAX96);
        }

        require(sqrtPriceAX96 > 0);

        amount0 = divRoundingUp(
            mulDivRoundingUp(
                (uint256(liquidity) << FixedPoint96.RESOLUTION), (sqrtPriceBX96 - sqrtPriceAX96), sqrtPriceBX96
            ),
            sqrtPriceAX96
        );
    }

    function calcAmount1Delta(uint160 sqrtPriceA96, uint160 sqrtPriceB96, uint128 liquidity)
        internal
        pure
        returns (uint256 amount1)
    {
        if (sqrtPriceA96 > sqrtPriceB96) {
            (sqrtPriceA96, sqrtPriceB96) = (sqrtPriceB96, sqrtPriceA96);
        }

        amount1 = mulDivRoundingUp(liquidity, (sqrtPriceB96 - sqrtPriceA96), FixedPoint96.Q96);
    }

    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    function divRoundingUp(uint256 numerator, uint256 denominator) internal pure returns (uint256 result) {
        assembly {
            result := add(div(numerator, denominator), gt(mod(numerator, denominator), 0))
        }
    }
}
