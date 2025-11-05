# 交易过滤器模块文档

## 概述

`trade_filters.mqh` 是一个综合的交易过滤模块，用于在下单前检查各种市场条件，确保只在合适的时机进行交易。

## 功能模块

### 1. 周末过滤 (Weekend Filter)

**目的**: 避免周末市场休市或流动性极低时段交易

**参数**:
- `WeekendFilterEnabled`: 是否启用周末过滤
- `FridayCloseHour`: 周五停止交易的时刻（默认21点）
- `MondayOpenHour`: 周一开始交易的时刻（默认3点）

**规则**:
- 周五指定时刻后禁止交易
- 周六、周日全天禁止交易
- 周一开盘前指定时间内禁止交易

### 2. 假日过滤 (Holiday Filter)

**目的**: 避免在重大节假日交易

**参数**:
- `HolidayFilterEnabled`: 是否启用假日过滤
- `HolidayList`: 假日列表，格式为 `YYYY-MM-DD,YYYY-MM-DD`

**示例**:
```
HolidayList = "2025-01-01,2025-12-25,2025-07-04"
```

### 3. 新闻过滤 (News Filter)

**目的**: 避免在重大新闻发布前后交易，防止剧烈波动

**参数**:
- `NewsFilterEnabled`: 是否启用新闻过滤
- `NewsAvoidMinutesBefore`: 新闻前避开的分钟数（默认30分钟）
- `NewsAvoidMinutesAfter`: 新闻后避开的分钟数（默认30分钟）
- `NewsEvents`: 新闻事件时间列表，格式为 `YYYY-MM-DD HH:MM;YYYY-MM-DD HH:MM`

**示例**:
```
NewsEvents = "2025-11-06 14:30;2025-11-07 20:00"
```

**建议**: 使用外部新闻日历API或手动维护重要新闻列表（如NFP、央行利率决议）

### 4. 点差过滤 (Spread Filter)

**目的**: 避免在点差异常扩大时交易，减少滑点成本

**参数**:
- `SpreadFilterEnabled`: 是否启用点差过滤
- `MaxSpreadPoints`: 绝对最大点差限制（默认30点）
- `NormalSpreadMultiplier`: 正常点差倍数（默认2.5倍）

**工作原理**:
1. 自动学习并记录"正常点差"（移动平均）
2. 如果当前点差超过绝对上限，拒绝交易
3. 如果当前点差超过正常点差的倍数，拒绝交易

**优点**:
- 适应不同时段的点差变化
- 自动识别异常点差扩大（如市场开盘、重大事件）

### 5. 波动过滤 (Volatility Filter)

**目的**: 确保市场波动在合理范围内，避免过度平静或过度剧烈

**参数**:
- `VolatilityFilterEnabled`: 是否启用波动过滤
- `ATRPeriod`: ATR计算周期（默认14）
- `MinATRValue`: 最小ATR值（默认0.0010）
- `MaxATRValue`: 最大ATR值（默认0.0200）

**工作原理**:
- 使用ATR（Average True Range）衡量市场波动
- 波动过小：市场可能盘整，信号不可靠
- 波动过大：市场可能失控，风险过高

## 使用方法

### 基本用法

```mql4
#include "risk/trade_filters.mqh"

int OnInit() {
   // 初始化过滤器
   InitTradeFilters();
   return INIT_SUCCEEDED;
}

void OnTick() {
   // 检查是否允许交易
   FilterResult result = CanTrade(Symbol());
   
   if(!result.passed) {
      // 被过滤器拒绝
      Print("交易被拒绝: ", result.reason);
      return;
   }
   
   // 通过所有过滤器，可以执行交易逻辑
   ExecuteTradeLogic();
}
```

### 在下单前检查

```mql4
bool OpenOrder(int orderType, double lots) {
   // 1. 过滤器检查
   FilterResult filter = CanTrade(Symbol());
   if(!filter.passed) {
      LogFilterRejection("开仓检查", filter.reason);
      return false;
   }
   
   // 2. 其他风控检查
   // ...
   
   // 3. 执行下单
   int ticket = OrderSend(...);
   
   return ticket > 0;
}
```

## 配置文件集成

所有参数应该从 `config/params.default.json` 加载：

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
      "2025-12-25"
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

## 日志示例

### 通过过滤器
```
[TradeFilters] 所有过滤器通过
[Example] ✓ 允许交易 - 周几: 3 | 点差: 2.1 (正常: 2.0) | ATR: 0.00145
```

### 被过滤器拒绝
```
[TradeFilters] 周末过滤 拒绝: 周五 21:00 之后禁止交易
[TradeFilters] 点差过滤 拒绝: 点差过大: 45.0 点 (上限: 30 点)
[TradeFilters] 新闻过滤 拒绝: 新闻事件避开时段: 2025-11-06 14:30 (前30分钟/后30分钟)
[TradeFilters] 波动过滤 拒绝: 波动过大: ATR=0.02500 (最大: 0.02000)
```

## 最佳实践

1. **优先级排序**: 过滤器按周末→假日→新闻→点差→波动的顺序检查
2. **日志记录**: 所有拒绝都应该记录到日志，便于后续分析
3. **参数调优**: 根据不同品种和策略调整参数
4. **动态更新**: 
   - 新闻列表应定期更新
   - 假日列表每年更新
   - 点差基准自动学习

5. **回测注意**: 
   - 回测时应启用所有过滤器
   - 检查过滤器是否过度限制交易机会
   - 统计各过滤器的拒绝率

## 扩展建议

### 1. 外部新闻日历API

集成第三方新闻日历（如 ForexFactory, Investing.com）：

```mql4
// 伪代码
bool CheckNewsCalendar() {
   string events = FetchNewsFromAPI();
   // 解析并检查
}
```

### 2. 动态参数调整

根据市场状态动态调整参数：

```mql4
void AdjustFilterParameters() {
   // 波动较大时，放宽点差限制
   if(GetMarketVolatility() > 0.015) {
      MaxSpreadPoints = 50;
   }
}
```

### 3. 历史统计

记录过滤器历史表现：

```mql4
struct FilterStats {
   int totalChecks;
   int rejections;
   double rejectionRate;
};
```

## 测试建议

1. **单元测试**: 测试每个过滤器的独立功能
2. **集成测试**: 测试多个过滤器组合效果
3. **回测验证**: 使用历史数据验证过滤器有效性
4. **实盘监控**: 记录过滤器在实盘中的表现

## 注意事项

⚠️ **时区问题**: 
- MT4使用服务器时间，注意与当地时间的差异
- 新闻时间应使用服务器时区

⚠️ **重绘风险**: 
- 本模块不使用未来数据，无重绘风险
- ATR使用固定周期，符合项目规范

⚠️ **性能考虑**:
- 过滤器检查应该快速（< 1ms）
- 避免在OnTick中频繁调用复杂计算

## 维护清单

- [ ] 每年更新假日列表
- [ ] 每周检查重大新闻事件并更新
- [ ] 每月检查过滤器拒绝率统计
- [ ] 每季度评估参数设置是否合理
- [ ] 记录异常点差扩大事件，分析原因

