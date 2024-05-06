//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import "./interfaces/IUniswapV3PoolDeployer.sol";
import "./UniswapV3Pool.sol";

contract UniswapV3Factory is IUniswapV3PoolDeployer {
    error PoolAdreadyExists();
    error ZeroAddressNotAllowed();
    error TokenMustBeDifferent();
    error UnsupportedTickSpacing();

    event PoolCreated(address indexed token0, address indexed token1, uint256 indexed tickSpacing, address pool);

    PoolParameters public parameters;

    mapping(uint24 => bool) tickSpacings;
    mapping(address => mapping(address => mapping(uint24 => address))) public pools;

    constructor() {
        tickSpacings[10] = true;
        tickSpacings[60] = true;
    }

    function createPool(address tokenX, address tokenY, uint24 tickSpacing) public returns (address pool) {
        if (tokenX == tokenY) revert TokenMustBeDifferent();
        if (!tickSpacings[tickSpacing]) revert UnsupportedTickSpacing();
        (tokenX, tokenY) = tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);

        if (tokenX == address(0)) revert ZeroAddressNotAllowed();
        if (pools[tokenX][tokenY][tickSpacing] != address(0)) {
            revert PoolAdreadyExists();
        }

        parameters = PoolParameters({factory: address(this), token0: tokenX, token1: tokenY, tickSpacing: tickSpacing});

        pool = address(new UniswapV3Pool{salt: keccak256(abi.encodePacked(tokenX, tokenY, tickSpacing))}());

        delete parameters;
        pools[tokenX][tokenY][tickSpacing] = pool;
        pools[tokenY][tokenX][tickSpacing] = pool;

        emit PoolCreated(tokenX, tokenY, tickSpacing, pool);
    }
}
