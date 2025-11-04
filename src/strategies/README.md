# 策略模块

此目录包含策略实现文件。

## 职责

- 生成交易信号（BUY/SELL/NONE）
- 纯函数实现（不依赖终端状态）
- 无重绘、无未来函数

## 示例文件结构

```
strategies/
├─ strategy_interface.mqh    # 策略接口定义
├─ ma_cross.mqh              # 均线交叉策略
├─ breakout.mqh              # 突破策略
└─ trend_follow.mqh          # 趋势跟踪策略
```

