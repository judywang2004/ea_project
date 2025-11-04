Context: This repo contains an MQL4/5 Expert Advisor. Review the open PR:

## 🚨 交易特定风险（Critical）
- Find trading-specific risks:
  * look-ahead bias / repainting indicators
  * time zone / DST / session filters
  * symbol digits, tick size/value, StopLevel and freeze level
  * slippage, spread widening, market gaps (weekend/news)
  * order retry logic, error codes, partial fills, requotes
  * FIFO/NFA compatibility, margin check, trade context busy
  * ATR/volatility-based position sizing correctness
  * ✅ **必须检查：周末/假日/重大新闻过滤**
  * ✅ **必须检查：点差 spike 保护**（动态监控点差异常）
  * ✅ **必须检查：波动率异常保护**（ATR 过高禁止交易）
  * ✅ **必须检查：跳空保护**（周末/假日后检测）

## 🔴 风控红线（Hard Limits）
  * ✅ risk limits respected (<=0.5% per trade)
  * ✅ max DD <=10% (停止交易机制)
  * ✅ 最大 EA 总风险 ≤ 2%（所有持仓）
  * ✅ **禁止马丁、加倍补仓、网格**（除非有文档说明+独立风控）
  * ✅ **所有风险参数禁止硬编码**

## 🔄 EA 生命周期
  * ✅ OnInit 必须检查所有品种参数合法
  * ✅ OnInit 必须验证所有配置参数
  * ✅ OnDeinit 必须清理资源（图形对象、指标句柄）
  * ✅ 支持参数热更新或明确说明需重启

## ✅ 参数验证（Validation）
  * ✅ RiskPercent ∈ (0, 1]
  * ✅ MaxSpreadPoints > 0
  * ✅ ATRPeriod >= 1
  * ✅ SessionStartHour/EndHour ∈ [0,23]
  * ✅ MagicNumber > 0
  * ✅ 参数验证失败必须禁止 EA 运行

## 🔀 交易模式管理
  * ✅ 支持的模式必须有文档说明（单向/双向/反手/加仓/对冲）
  * ✅ 检测互斥模式冲突（如反手+加仓）
  * ✅ 每种模式的风险特征清晰

## 🏗️ 架构与代码质量
- Check architecture layering (strategy/risk/exec separation).
- Verify no magic-number collisions, unique ticket handling.
- Ensure parameters live in config/*.json, no hard-coded risk.
- Enforce robust logging and backtest/reproducibility (reports/).
- Request missing tests (sanity_checks.py) or add them.
- If issues found, open a correction PR.

Output:
1) Summary, 2) Critical issues, 3) Non-critical suggestions,
4) Concrete diffs to apply, 5) Optional: open a fix PR.

