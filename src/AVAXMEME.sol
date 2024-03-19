// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

contract AVAXMEME is ERC20 {
    // deadline 为 3 天后
    uint256 public immutable deadline = block.timestamp + 3 days;
    // 退款时间为 deadline 之后 1 小时
    uint256 public immutable refundTime = block.timestamp + 3 days + 1 hours;
    // 目标额度为 1000 AVAX
    uint256 public immutable targetAmount = 1000 ether;
    // LP 是否开启，默认为 false
    bool public LPopen;
    // WAVAX
    IWETH WAVAX = IWETH(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    // 创建 uniswapV2 的池子
    address pair = IUniswapV2Factory(0x9e5A52f57b3038F1B8EeE45F28b3C1967e22799C).createPair(
        address(this),
        address(WAVAX)
    );

    // 全称为 AVAXMEME，符号为 AVME
    constructor() ERC20("AVAXMEME", "AVME") {}

    receive() external payable {
        // 不能低于 1 AVAX
        require(msg.value >= 1 ether, "less than 1 AVAX");
        // 不能高于 100 AVAX
        require(msg.value <= 100 ether, "greater than 100 AVAX");
        // 要在截止日期之前
        require(block.timestamp < deadline, "deadline reached");
        // 1 个 AVAX 送 10000 个 AVAXMEME
        _mint(msg.sender, 10000 * msg.value);
        // 单个账户额度不能高于 100 AVAX
        require(balanceOf(msg.sender) <= 10000 * 100 ether, "reached limit of 100 AVAX");
    }

    function _transfer(address from, address to, uint256 amount) override internal {
        // LPopen 为 true 才能转账
        require(LPopen, "wait LP open");
        super._transfer(from, to, amount);
    }

    function _refund(address sender) internal {
        // 需要在 refundTime 之后
        require(block.timestamp >= refundTime, "wait refundTime");
        // 不能在 LP 开启后
        require(!LPopen, "LP opened");
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
        // deadline 之前不能开启 LP
        require(block.timestamp >= deadline,"wait deadline");
        // 不能在 LP 开启后
        require(!LPopen, "LP opened");
        uint256 amountWAVAX = address(this).balance;
        // 达不到目标额度不能开启 LP
        require(amountWAVAX >= targetAmount, "target not reached");
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
