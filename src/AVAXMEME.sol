// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract AVAXMEME is ERC20 {
    // deadline 为 3 天后
    uint256 public deadline = block.timestamp + 3 days;
    // 退款时间为 deadline 之后 1 小时
    uint256 public refundTime = deadline + 1 hours;
    // 最低额度 1000 AVAX
    uint256 public minAVAX = 1000;
    // LP 是否开启，默认为 false
    bool public LPopen;

    // 全称为 AVAXMEME，符号为 AVME
    constructor() ERC20("AVAXMEME", "AVME") {}

    receive() external payable {
        // 低于 1 AVAX 或高于 100 AVAX 都不接收
        require(msg.value >= 1 ether && msg.value <= 100 ether, "too rich or too small");
        // deadline 之后不接收 AVAX 转账
        require(block.timestamp < deadline, "too late");
        // 冲 1 个 AVAX 送 10000 个 AVAXMEME
        _mint(msg.sender, 10000 * msg.value);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        // LPopen 为 true 才能转账
        require(LPopen, "LP not open");
        super._transfer(from, to, amount);
    }

    function _refund(address sender) internal {
        // refundTime 之后还没有开启 LP 才能退款
        require(block.timestamp >= refundTime && !LPopen, "too early");
        uint256 balance = balanceOf(sender);
        // 回收 AVAXMEME
        _burn(sender, balance);
        // 退回 AVAX
        payable(sender).transfer(balance / 10000);
    }

    function refund() external {
        // 给自己退款
        _refund(msg.sender);
    }

    function batchRefund(address[] memory senderList) external {
        for (uint256 i; i < senderList.length; i++) {
            // 批量退款
            _refund(senderList[i]);
        }
    }

    function openLP() external {
        // deadline 之前不能开启 LP，openLP 只能调用一次
        require(block.timestamp >= deadline && !LPopen, "too early");
        uint256 amountWAVAX = address(this).balance;
        // 最低额度达不到不能开启 LP
        require(amountWAVAX >= minAVAX, "balance not reached");
        IWETH WAVAX = IWETH(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
        // 创建 uniswapV2 的池子
        address pair = IUniswapV2Factory(0x9e5A52f57b3038F1B8EeE45F28b3C1967e22799C).createPair(
            address(this),
            address(WAVAX)
        );
        // AVAX 换成 WAVAX
        WAVAX.deposit{value: amountWAVAX}();
        // 添加池子流动性，所有 WAVAX + 1/4 总量的 AVAXMEME
        WAVAX.transfer(pair, amountWAVAX);
        _mint(pair, totalSupply() / 4);
        // 燃烧 LP
        IUniswapV2Pair(pair).mint(address(0));
        // LPopen 变成 true
        LPopen = true;
    }
}
