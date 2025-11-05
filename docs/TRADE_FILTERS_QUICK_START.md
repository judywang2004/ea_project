# 交易过滤器快速开始

## 🎯 功能概述

交易过滤器模块是EA项目的核心风控组件，在每次交易前自动检查5大关键条件，确保只在最佳市场环境下交易。

## 📋 五大过滤器

| 过滤器 | 目的 | 关键参数 |
|--------|------|----------|
| 🗓️ 周末过滤 | 避免周末流动性不足 | `FridayCloseHour`, `MondayOpenHour` |
| 🎉 假日过滤 | 避免节假日市场休市 | `HolidayList` |
| 📰 新闻过滤 | 避免重大新闻波动 | `NewsEvents`, `NewsAvoidMinutesBefore/After` |
| 💰 点差过滤 | 防止点差异常扩大 | `MaxSpreadPoints`, `NormalSpreadMultiplier` |
| 📊 波动过滤 | 确保市场波动适中 | `ATRPeriod`, `MinATRValue`, `MaxATRValue` |

## 🚀 快速集成（3步）

### 步骤 1: 包含头文件

```mql4
#include "risk/trade_filters.mqh"
```

### 步骤 2: 初始化过滤器

```mql4
int OnInit() {
   InitTradeFilters();
   return INIT_SUCCEEDED;
}
```

### 步骤 3: 在交易前检查

```mql4
void OnTick() {
   // 检查是否允许交易
   FilterResult result = CanTrade(Symbol());
   
   if(!result.passed) {
      // 被过滤器拒绝
      Print("交易被拒绝: ", result.reason);
      return;
   }
   
   // 通过所有过滤器，执行交易逻辑
   ExecuteTradeLogic();
}
```

## 🔧 配置示例

在 `config/params.default.json` 中：

```json
{
  "filters": {
    "weekend_filter_enabled": true,
    "holiday_filter_enabled": true,
    "news_filter_enabled": true,
    "spread_filter_enabled": true,
    "volatility_filter_enabled": true,
    
    "max_spread_points": 30,
    "normal_spread_multiplier": 2.5,
    
    "atr_period": 14,
    "min_atr_value": 0.0010,
    "max_atr_value": 0.0200,
    
    "holidays": [
      "2025-01-01",
      "2025-12-25",
      "2025-07-04",
      "2025-11-27"
    ]
  },
  "trading_hours": {
    "friday_close_hour": 21,
    "monday_open_hour": 3,
    "news_avoid_minutes_before": 30,
    "news_avoid_minutes_after": 30
  }
}
```

## 📝 实际使用案例

### 案例1: 开仓前检查

```mql4
bool OpenBuyOrder(double lots) {
   // 1. 过滤器检查
   FilterResult filter = CanTrade(Symbol());
   if(!filter.passed) {
      LogFilterRejection("开多单", filter.reason);
      return false;
   }
   
   // 2. 其他风控检查（止损距离、保证金等）
   if(!CheckRiskManagement()) {
      return false;
   }
   
   // 3. 执行下单
   double price = Ask;
   double sl = price - 100 * Point;
   double tp = price + 200 * Point;
   
   int ticket = OrderSend(Symbol(), OP_BUY, lots, price, 3, sl, tp, 
                          "Buy Order", MagicNumber, 0, clrGreen);
   
   if(ticket > 0) {
      Print("[Success] Buy order opened: #", ticket);
      return true;
   }
   
   return false;
}
```

### 案例2: 定时检查状态

```mql4
void OnTick() {
   static datetime lastCheckTime = 0;
   
   // 每5分钟检查一次过滤器状态
   if(TimeCurrent() - lastCheckTime > 300) {
      lastCheckTime = TimeCurrent();
      
      FilterResult result = CanTrade(Symbol());
      string status = GetFilterStatus(Symbol());
      
      if(result.passed) {
         Print("✓ 交易窗口开放 - ", status);
      } else {
         Print("✗ 交易窗口关闭 - ", result.reason);
      }
   }
}
```

## 📊 日志输出示例

### ✅ 通过过滤器
```
[TradeFilters] 初始化过滤器模块
[TradeFilters] 周末过滤: 启用
[TradeFilters] 假日过滤: 启用
[TradeFilters] 新闻过滤: 启用
[TradeFilters] 点差过滤: 启用
[TradeFilters] 波动过滤: 启用
[Example] ✓ 允许交易 - 周几: 3 | 点差: 2.1 (正常: 2.0) | ATR: 0.00145
```

### ❌ 被过滤器拒绝
```
[TradeFilters] 周末过滤 拒绝: 周五 21:00 之后禁止交易
[TradeFilters] 点差过滤 拒绝: 点差过大: 45.0 点 (上限: 30 点)
[TradeFilters] 新闻过滤 拒绝: 新闻事件避开时段: 2025-11-06 14:30 (前30分钟/后30分钟)
[TradeFilters] 波动过滤 拒绝: 波动过大: ATR=0.02500 (最大: 0.02000)
```

## 🧪 测试配置

运行配置验证脚本：

```bash
cd scripts
python3 test_filters.py
```

输出示例：
```
============================================================
交易过滤器配置验证
============================================================
✓ 配置文件加载成功

✅ 配置验证通过！

📅 假日覆盖检查:
  ✓ New Year (2025-01-01)
  ✓ Independence Day (2025-07-04)
  ✓ Christmas (2025-12-25)

🔧 当前启用的过滤器:
  周末过滤: ✓ 启用
  假日过滤: ✓ 启用
  新闻过滤: ✓ 启用
  点差过滤: ✓ 启用
  波动过滤: ✓ 启用
```

## ⚙️ 品种特定配置建议

### EURUSD / GBPUSD (主要货币对)
```json
{
  "max_spread_points": 20,
  "min_atr_value": 0.0008,
  "max_atr_value": 0.0150
}
```

### XAUUSD (黄金)
```json
{
  "max_spread_points": 100,
  "min_atr_value": 0.0050,
  "max_atr_value": 0.0500
}
```

### USDJPY (交叉盘)
```json
{
  "max_spread_points": 30,
  "min_atr_value": 0.0010,
  "max_atr_value": 0.0200
}
```

## 🔍 常见问题

### Q1: 点差过滤一直拒绝交易？
**A:** 可能是 `MaxSpreadPoints` 设置过小。检查当前品种的正常点差范围，适当调高上限。

### Q2: 如何临时禁用某个过滤器？
**A:** 在配置文件中设置对应的 `*_enabled` 为 `false`，或在代码中注释掉相应检查。

### Q3: 波动过滤频繁触发？
**A:** ATR阈值可能不适合当前品种。运行一段时间后，统计正常ATR范围并调整 `min_atr_value` 和 `max_atr_value`。

### Q4: 如何添加新的新闻事件？
**A:** 更新配置文件中的 `NewsEvents` 参数，格式：`"YYYY-MM-DD HH:MM;YYYY-MM-DD HH:MM"`

### Q5: 回测时过滤器也生效吗？
**A:** 是的！过滤器在回测中同样工作，这样可以更真实地模拟实盘表现。

## 📚 进一步学习

- [完整文档](TRADE_FILTERS.md) - 详细技术文档
- [配置文件](../config/params.default.json) - 参数配置
- [示例代码](../src/risk/trade_filters_example.mq4) - 使用示例
- [验证脚本](../scripts/test_filters.py) - 配置验证工具

## ⚠️ 重要提醒

1. **时区**: MT4使用服务器时间，注意与本地时间的差异
2. **无重绘**: 本模块使用固定缓冲指标（ATR），无未来函数
3. **日志**: 所有拒绝都会记录日志，便于后续分析优化
4. **假日更新**: 每年需要更新假日列表
5. **新闻更新**: 建议每周检查并更新重大新闻事件

---

**开始使用吧！** 如有问题，查看完整文档或提交Issue。

