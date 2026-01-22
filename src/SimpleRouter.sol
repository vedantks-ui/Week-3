// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./FluxEthPool.sol"; 
interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
    function transfer(address to,uint value) external returns(bool);
}

contract SimpleRouter {
    address public immutable ETH; 
    address public immutable FLUX;
    address public immutable POOL;
    constructor(address _eth,address _flux,address _pool) {
        ETH = _eth;
        FLUX = _flux;
        POOL = _pool;
    }

    function addLiquidity(uint amountFlux) external payable {
        IWETH(ETH).deposit{value: msg.value}();
        IERC20(ETH).transfer(POOL,msg.value);
        IERC20(FLUX).transferFrom(msg.sender,address(this),amountFlux);
        IERC20(FLUX).transfer(POOL,amountFlux);
        IUniswapV2Pair(POOL).mint(msg.sender);
    }

    function swapEthForFlux(uint minFlux) external payable {
        IWETH(ETH).deposit{value: msg.value}();
        IERC20(ETH).transfer(POOL,msg.value);

        (uint ethReserve,uint fluxReserve,) = IUniswapV2Pair(POOL).getReserves();
        
        uint amountInWithFee = msg.value * 997;
        uint numerator = amountInWithFee * fluxReserve;
        uint denominator = (ethReserve * 1000) + amountInWithFee;
        uint fluxAmountOut = numerator / denominator;

        require(fluxAmountOut >= minFlux, "Slippage Error");
        IUniswapV2Pair(POOL).swap(0, fluxAmountOut, msg.sender, "");
    }
    
    receive() external payable {}
}