// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IUniswapV2Pair {
    function mint(address to) external returns(uint liquidity);
    function swap(uint ethAmountOut,uint fluxAmountOut,address to,bytes calldata data) external;
    function getReserves() external view returns (uint ethReserve,uint fluxReserve,uint blockTimestamp);
}
contract FluxEthPool {
    using Math for uint256;
    address public immutable FACTORY;
    address public immutable ETH;
    address public immutable FLUX;


    uint public ethReserve;
    uint public fluxReserve;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    modifier lock(){
        require(msg.sender==tx.origin);
        _;
    }

    constructor(address _eth,address _flux){
        FACTORY = msg.sender;
        ETH = _eth;
        FLUX = _flux;
    }

    function getReserves() public view returns(uint,uint,uint) {
        return (ethReserve,fluxReserve,block.timestamp);
    }

    function mint(address to) external lock returns (uint liquidity) {
        uint ethBalance = IERC20(ETH).balanceOf(address(this));
        uint fluxBalance = IERC20(FLUX).balanceOf(address(this));
        if (totalSupply == 0) {
            liquidity =sqrt(ethBalance*fluxBalance)-1000;
            totalSupply = 1000; 
        } else {
            liquidity = min((ethBalance * totalSupply) / ethReserve, (fluxBalance * totalSupply) / fluxReserve);
        }
        balanceOf[to] =balanceOf[to]+liquidity;
        totalSupply =totalSupply+liquidity;
        _update(ethBalance, fluxBalance);
    }

    function swap(uint ethAmountOut,uint fluxAmountOut,address to,bytes calldata) external lock {
        if (ethAmountOut > 0) IERC20(ETH).transfer(to, ethAmountOut);
        if (fluxAmountOut > 0) IERC20(FLUX).transfer(to, fluxAmountOut);
        uint ethBalance = IERC20(ETH).balanceOf(address(this));
        uint fluxBalance = IERC20(FLUX).balanceOf(address(this));
        uint ethAmountIn = ethBalance > ethReserve - ethAmountOut ?ethBalance-(ethReserve-ethAmountOut) : 0;
        uint fluxAmountIn = fluxBalance > fluxReserve - fluxAmountOut ? fluxBalance -(fluxReserve-fluxAmountOut) : 0;
        require(ethAmountIn > 0 || fluxAmountIn > 0, "Insufficient Input");
        
        uint ethBalanceAdjusted =(ethBalance * 1000)-(ethAmountIn * 3);
        uint fluxBalanceAdjusted = (fluxBalance * 1000) -(fluxAmountIn * 3);
        require(ethBalanceAdjusted * fluxBalanceAdjusted >= ethReserve*fluxReserve*1000**2, "K Constant Failed");
        _update(ethBalance, fluxBalance);
    }

    function _update(uint ethBalance,uint fluxBalance) private {
        ethReserve = ethBalance;
        fluxReserve = fluxBalance;
    }
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y/2 + 1;
            while (x < z) {
                z = x;
                x = (y/x + x) / 2;
            }
        } else if (y!= 0) {
            z = 1;
        }
    }
    function min(uint x, uint y) internal pure returns (uint z) { z = x < y ? x : y; }
}