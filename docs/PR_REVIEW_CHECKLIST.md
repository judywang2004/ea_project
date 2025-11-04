# Pull Request 审查清单

在提交或审查 PR 时，请确保以下所有项目都已检查并通过。

## 📋 通用检查

- [ ] 代码符合项目架构（策略/风控/执行分层）
- [ ] 无硬编码的风险参数（全部在 `config/params.default.json`）
- [ ] 所有参数有合理的默认值和注释
- [ ] 代码有适当的注释（尤其是复杂逻辑）
- [ ] 遵循项目命名规范

## 🎯 策略相关

### 指标开发
- [ ] 无重绘型指标（使用固定缓冲写法）
- [ ] 无未来函数（look-ahead bias）
- [ ] 文档中明确说明指标特性
- [ ] 使用 `IndicatorCounted()` (MQL4) 或 `prev_calculated` (MQL5)

### 信号生成
- [ ] 信号生成为纯函数（不依赖全局状态或终端数据）
- [ ] 可离线测试（不需要实时行情）
- [ ] 有清晰的入场/出场逻辑
- [ ] 信号原因记录到日志

## 🛡️ 风险管理

### 仓位计算
- [ ] 基于账户风险百分比计算手数
- [ ] 默认风险 ≤ 0.5% per trade
- [ ] 支持 ATR 或固定点数止损
- [ ] 检查 broker 的 MinLot、MaxLot、LotStep

### 风控限制（硬限制 🔴）
- [ ] ✅ **最大单笔风险** ≤ 0.5% per trade（或配置值）
- [ ] ✅ **最大 EA 总风险**（所有持仓总风险 ≤ 2%，或配置值）
- [ ] ✅ **最大回撤** ≤ 10%（达到后停止交易）
- [ ] ✅ **禁止马丁、加倍补仓、网格**（除非策略文档明确说明并有独立风控）
- [ ] ✅ **所有风险参数禁止硬编码**（必须在 config 中可配置）
- [ ] 点差上限检查（默认 ≤30 points）
- [ ] 最小止损距离检查（大于 StopLevel）
- [ ] 止损/止盈距离符合 broker 要求（考虑 freeze level）
- [ ] 单日最大交易次数限制（防止频繁交易）
- [ ] 连续亏损后暂停交易机制

### 交易时段与市场环境
- [ ] 交易时段过滤已实现
- [ ] 考虑时区和 DST 变化
- [ ] ✅ **必须实现周末、假日、重大新闻过滤**
- [ ] ✅ **必须实现点差 spike 保护**（实时监控点差异常）
- [ ] ✅ **必须实现波动率异常保护**（ATR 过高时禁止交易）
- [ ] 跳空保护（周末/假日后首个 tick 检测）
- [ ] 流动性检测（低流动性时段规避）

## 📦 订单执行

### 下单逻辑
- [ ] 使用封装的 OrderSend（不直接调用原生函数）
- [ ] 失败重试机制（有最大重试次数限制，不无穷重试）
- [ ] 错误码处理（requote、off quotes、trade context busy 等）
- [ ] Slippage 参数设置合理

### 订单修改
- [ ] OrderModify 包含错误处理
- [ ] 检查 freeze level（不在 freeze level 内修改）
- [ ] 追踪止损逻辑正确（不会反向移动）

### Broker 兼容性
- [ ] 兼容 NFA/FIFO 规则（如适用）
- [ ] 兼容 3 位和 5 位小数品种
- [ ] 正确处理 MarketInfo 参数
- [ ] 测试过部分成交场景

## 🔄 EA 生命周期管理

### OnInit 初始化
- [ ] ✅ **检查所有品种参数合法性**（digits、point、tick value 等）
- [ ] ✅ **验证配置参数有效性**（调用参数验证函数）
- [ ] 检查必要的历史数据是否足够（如 ATR 计算需要的 bar 数）
- [ ] 初始化全局变量和状态
- [ ] 返回合适的初始化状态码（INIT_SUCCEEDED/INIT_FAILED）
- [ ] 初始化失败时有清晰的错误提示

### OnDeinit 清理
- [ ] ✅ **必须清理资源**（删除图形对象、释放指标句柄）
- [ ] 保存必要的状态信息（如用于恢复）
- [ ] 记录 EA 停止原因和时间
- [ ] 不留下内存泄漏

### 参数热更新
- [ ] ✅ **支持重新加载参数无需重启 EA**（或明确说明需要重启）
- [ ] 参数修改后重新验证
- [ ] 关键参数变更记录到日志

## ✅ 参数验证（Validation）

### 参数范围检查
- [ ] ✅ **RiskPercent ∈ (0, 1]**（不能为负或超过 100%）
- [ ] ✅ **MaxSpreadPoints > 0**（必须为正数）
- [ ] ✅ **ATRPeriod >= 1**（至少需要 1 个周期）
- [ ] ✅ **SessionStartHour ∈ [0, 23]**（小时范围合法）
- [ ] ✅ **SessionEndHour ∈ [0, 23]**
- [ ] ✅ **MagicNumber > 0**（必须为正数且唯一）
- [ ] ✅ **StopLossPoints > 0**（止损距离必须大于 0）
- [ ] ✅ **MaxDailyTrades >= 0**（不能为负）

### 参数逻辑检查
- [ ] SessionStartHour < SessionEndHour（或处理跨日情况）
- [ ] MaxSlippage >= 0
- [ ] TakeProfit >= StopLoss（如果都设置的话）
- [ ] 参数验证失败时**禁止 EA 运行**
- [ ] 所有验证错误有详细日志输出

## 🔀 交易模式管理

### 模式定义
- [ ] ✅ **支持的交易模式必须有文档说明**
  - 单方向模式（仅 long/short）
  - 双向模式
  - 反手模式
  - 加仓模式
  - 对冲模式
- [ ] 每种模式的风险特征说明清楚

### 模式冲突检测
- [ ] ✅ **检测互斥模式冲突**（如：反手 + 加仓）
- [ ] 模式切换时检查现有持仓
- [ ] 模式参数组合验证（某些参数组合可能不合理）
- [ ] 模式切换记录到日志

### 模式风控
- [ ] 每种模式有独立的风控参数
- [ ] 复杂模式（如加仓、网格）有额外的总风险限制
- [ ] 模式启用/禁用开关在配置文件中

## 📊 市场数据

### 品种信息
- [ ] 动态读取品种参数（digits、point、tick value）
- [ ] 不假设固定的点数精度
- [ ] 正确计算点值和货币转换
- [ ] 处理点差扩大（周末/新闻）

### 时间处理
- [ ] 使用服务器时间（不依赖本地时间）
- [ ] 考虑 DST 变化
- [ ] 正确判断 K 线生成（避免每 tick 重复处理）

## 📝 日志与监控

### 日志完整性
- [ ] 所有订单操作都有日志（open/modify/close）
- [ ] 记录失败原因和错误码
- [ ] 记录风控拒绝的原因
- [ ] 止损移动记录到日志
- [ ] 日志有时间戳和严重级别

### 调试信息
- [ ] 关键变量值可输出（通过日志级别控制）
- [ ] 异常情况有详细错误信息
- [ ] 便于回溯问题

## 🧪 测试

### 静态检查
- [ ] 运行 `scripts/sanity_checks.py` 无错误
- [ ] 无 linter 警告（如适用）
- [ ] 代码通过编译（MQL4/MQL5）

### 单元测试
- [ ] 策略信号可独立测试
- [ ] 风控函数有边界测试
- [ ] 订单逻辑有模拟测试

### 回测验证
- [ ] 在 Strategy Tester 中通过
- [ ] 风险限制生效（无超风险交易）
- [ ] 订单日志完整
- [ ] 生成回测报告（使用 `scripts/export_report.py`）

## 🔒 安全性

### 魔术数字
- [ ] 每个 EA 实例有唯一的 magic number
- [ ] 不与其他 EA 冲突
- [ ] Magic number 在配置文件中定义

### Ticket 处理
- [ ] 不假设 ticket 连续性
- [ ] 正确处理 ticket 无效的情况
- [ ] 不依赖 OrderSelect 的顺序

### 并发控制
- [ ] 避免 trade context busy（重试或等待）
- [ ] 不同时修改同一订单
- [ ] OnTick 中避免长时间阻塞

## 📚 文档

### 代码文档
- [ ] 关键函数有注释说明
- [ ] 复杂算法有解释
- [ ] 参数含义清晰

### 项目文档
- [ ] README.md 更新（如有新功能）
- [ ] DESIGN.md 更新（如有架构变更）
- [ ] 配置文件示例更新

## ✅ 最终检查

- [ ] 本地编译通过
- [ ] 回测验证通过
- [ ] 日志输出正常
- [ ] 参数配置合理
- [ ] 代码审查通过（至少一人）

---

## 🚨 常见问题与最佳实践

### 参数验证
❌ **错误：** 不验证参数直接使用
```mql4
// 参数可能是负数或不合理值
double lots = CalculateLotSize(RiskPercent);
```

✅ **正确：** OnInit 中严格验证
```mql4
int OnInit() {
    // 验证风险参数
    if(RiskPercent <= 0 || RiskPercent > 1.0) {
        Print("错误：RiskPercent 必须在 (0, 1] 范围内，当前值：", RiskPercent);
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 验证点差上限
    if(MaxSpreadPoints <= 0) {
        Print("错误：MaxSpreadPoints 必须大于 0");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // 验证交易时段
    if(SessionStartHour < 0 || SessionStartHour > 23) {
        Print("错误：SessionStartHour 必须在 [0,23] 范围内");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    return INIT_SUCCEEDED;
}
```

### 点差 Spike 保护
❌ **错误：** 只检查静态点差上限
```mql4
if(Ask - Bid <= MaxSpread * Point) {
    OrderSend(...);
}
```

✅ **正确：** 动态监控点差异常
```mql4
// 计算当前点差
double currentSpread = (Ask - Bid) / Point;
double avgSpread = iMA(NULL, 0, 20, 0, MODE_SMA, PRICE_SPREAD, 0); // 如有点差历史

// 点差突然扩大 3 倍以上，可能是 spike
if(currentSpread > MaxSpreadPoints || currentSpread > avgSpread * 3) {
    Print("警告：点差异常 ", currentSpread, " points，暂停交易");
    return;  // 不交易
}
```

### 波动率异常保护
❌ **错误：** 不检查市场波动率
```mql4
// 任何时候都交易
if(signal) OrderSend(...);
```

✅ **正确：** 过滤极端波动
```mql4
double atr = iATR(Symbol(), PERIOD_H1, 14, 0);
double atrAvg = iMA(NULL, PERIOD_H1, 20, 0, MODE_SMA, atr, 0);

// ATR 突然增大 2 倍，市场异常波动
if(atr > atrAvg * 2.0) {
    Print("警告：波动率异常，ATR=", atr, " 平均=", atrAvg);
    return;  // 暂停交易
}
```

### 周末跳空保护
❌ **错误：** 周一开盘直接交易
```mql4
if(DayOfWeek() == 1) {  // 周一
    OrderSend(...);  // 危险！
}
```

✅ **正确：** 检测跳空后等待
```mql4
bool IsAfterWeekendGap() {
    if(DayOfWeek() == 1) {  // 周一
        double mondayOpen = iOpen(Symbol(), PERIOD_D1, 0);
        double fridayClose = iClose(Symbol(), PERIOD_D1, 1);
        double gapPoints = MathAbs(mondayOpen - fridayClose) / Point;
        
        if(gapPoints > 50) {  // 跳空超过 50 点
            Print("检测到周末跳空：", gapPoints, " points");
            return true;
        }
    }
    return false;
}

// 使用
if(!IsAfterWeekendGap() && TimeCurrent() - iTime(Symbol(), PERIOD_H1, 0) > 3600) {
    // 周一开盘后至少等待 1 小时
    OrderSend(...);
}
```

### 马丁策略检测
❌ **错误：** 隐藏的加倍补仓
```mql4
// 亏损后加倍手数
if(lastTradeLoss) {
    lots = lots * 2;  // 马丁格尔！
}
```

✅ **正确：** 固定风险比例
```mql4
// 每笔交易独立计算，基于账户权益
double lots = CalculateLotSize(Symbol(), stopLossPoints, RiskPercent);
// 不依赖上一笔交易结果
```

### EA 生命周期管理
❌ **错误：** 不清理资源
```mql4
void OnDeinit(const int reason) {
    // 什么都不做
}
```

✅ **正确：** 完整清理
```mql4
void OnDeinit(const int reason) {
    // 删除图形对象
    ObjectsDeleteAll(0, "EA_");
    
    // 释放指标句柄（MQL5）
    if(atrHandle != INVALID_HANDLE) {
        IndicatorRelease(atrHandle);
    }
    
    // 记录停止原因
    string reasonText = "";
    switch(reason) {
        case REASON_PROGRAM: reasonText = "手动停止"; break;
        case REASON_REMOVE: reasonText = "从图表移除"; break;
        case REASON_RECOMPILE: reasonText = "重新编译"; break;
        case REASON_PARAMETERS: reasonText = "参数修改"; break;
        case REASON_ACCOUNT: reasonText = "账户切换"; break;
        default: reasonText = "其他原因";
    }
    Print("EA 停止，原因：", reasonText, " (", reason, ")");
}
```

### 重绘指标
❌ **错误：** 每次重新计算所有历史 bar
```mql4
for(int i = 0; i < Bars; i++) {
    buffer[i] = calculate(i);
}
```

✅ **正确：** 只计算新的 bar
```mql4
int counted = IndicatorCounted();
int limit = Bars - counted - 1;
for(int i = limit; i >= 0; i--) {
    buffer[i] = calculate(i);
}
```

### 硬编码风险
❌ **错误：**
```mql4
double lots = 0.1;  // 硬编码
OrderSend(..., lots, ...);
```

✅ **正确：**
```mql4
double lots = CalculateLotSize(symbol, sl_distance, RiskPercent);
OrderSend(..., lots, ...);
```

### 无错误处理
❌ **错误：**
```mql4
int ticket = OrderSend(...);
// 直接继续，没有检查
```

✅ **正确：**
```mql4
int ticket = OrderSend(...);
if(ticket < 0) {
    int error = GetLastError();
    Print("OrderSend failed: ", ErrorDescription(error));
    // 重试或其他处理
}
```

### 点数精度假设
❌ **错误：**
```mql4
double sl = OrderOpenPrice() - 50 * Point;  // 假设 5 位小数
```

✅ **正确：**
```mql4
double sl = OrderOpenPrice() - 50 * Point * GetPointMultiplier(symbol);
```

---

## 审查人签名

- **审查人：** _______________
- **日期：** _______________
- **结果：** [ ] 通过  [ ] 需修改  [ ] 拒绝
- **备注：**


