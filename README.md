# EA Project

MQL4/5 Expert Advisor with modular architecture and strict risk management.

## 项目结构

```
ea-project/
├─ src/                    # 源代码
│   ├─ main.mq4|mq5       # EA 入口
│   ├─ indicators/        # 自定义指标（避免重绘）
│   ├─ strategies/        # 策略模块（信号生成）
│   ├─ risk/              # 风险与仓位 sizing
│   ├─ exec/              # 下单/风控/追踪止损
│   └─ utils/             # 时间/点值/点差/日志
├─ config/                # 配置文件
├─ backtests/             # 回测相关
├─ scripts/               # Python 工具脚本
└─ docs/                  # 文档
```

## 核心原则

- **模块职责单一**：策略／风控／执行分层
- **无重绘指标**：固定缓冲写法
- **风险管理**：≤0.5%/trade，基于ATR动态止损
- **参数集中**：所有参数在 `config/params.default.json`
- **严格日志**：订单、修改、止损移动、拒单原因
- **可测试性**：信号生成为纯函数

## 快速开始

1. 复制 `config/params.default.json` 并根据需要调整参数
2. 编译 `src/main.mq4` 或 `src/main.mq5`
3. 在 MT4/MT5 中加载 EA
4. 查看日志确认运行状态

## 回测

1. 使用 `backtests/mt_settings/` 中的 .set 文件
2. 运行回测后，使用 `scripts/export_report.py` 生成报告
3. 运行 `scripts/sanity_checks.py` 进行参数验证

## 交易过滤器

项目包含完整的交易过滤模块 (`src/risk/trade_filters.mqh`)，用于交易前风控验证：

### 五大过滤器
1. **周末过滤** - 避免周末市场休市时段
2. **假日过滤** - 避免重大节假日
3. **新闻过滤** - 避免重大新闻发布前后
4. **点差过滤** - 监控点差异常扩大
5. **波动过滤** - 确保市场波动在合理范围（基于ATR）

### 使用示例
```mql4
#include "risk/trade_filters.mqh"

// 在下单前检查
FilterResult result = CanTrade(Symbol());
if(!result.passed) {
   Print("交易被拒绝: ", result.reason);
   return;
}
```

### 配置验证
```bash
cd scripts
python3 test_filters.py  # 验证过滤器配置
```

详细文档：[TRADE_FILTERS.md](docs/TRADE_FILTERS.md)

## 交易策略

### 🏆 趋势金字塔策略（机构级实现）

专业的趋势跟随加仓策略，采用多重确认机制和严格风控。

**核心特点**：
- 📈 三均线系统 + ADX趋势强度过滤
- 🔺 金字塔加仓（黄金分割比例0.618）
- 🛡️ 动态ATR止损 + 追踪止损 + 盈亏平衡
- 💰 分批止盈 + 趋势反转自动平仓
- ⚖️ 严格风险管理（初始1%，总风险≤3%）

**策略文件**：
- EA主文件：`src/strategies/PyramidTrend_EA.mq4`
- 策略模块：`src/strategies/pyramid_trend.mqh`
- 详细文档：[PYRAMID_TREND_STRATEGY.md](docs/PYRAMID_TREND_STRATEGY.md)

**快速开始**：
```mql4
// 1. 将EA拖到图表上
// 2. 调整参数（或使用默认值）
// 3. 启用自动交易
// 4. 监控屏幕左上角状态显示
```

**适合品种**：EURUSD, GBPUSD, XAUUSD  
**推荐周期**：H1, H4, D1  
**风险等级**：中等（可调）

## 开发规范

本项目配置了 Cursor AI 辅助开发规则（`.cursorrules`）和 Codex Cloud 代码审查提示（`.codex/review.md`），确保：
- 模块职责单一（策略/风控/执行分层）
- 无重绘指标，参数集中管理
- 交易前风控验证（点差、止损、时段、步进）
- 严格的订单处理和日志记录
- 基于风险占比的仓位计算
- 代码可测试性和可复现性

## 文档

### 快速开始 🚀
- **[PYRAMID_QUICK_START.md](docs/PYRAMID_QUICK_START.md)** - 安装和使用教程
- **[DEMO_MODE_GUIDE.md](docs/DEMO_MODE_GUIDE.md)** - Demo模式实时测试指南 🆕

### 策略文档
- [PYRAMID_TREND_STRATEGY.md](docs/PYRAMID_TREND_STRATEGY.md) - 趋势金字塔策略完整文档
- [STRATEGY_COMPARISON.md](docs/STRATEGY_COMPARISON.md) - 与Turtle/Donchian系统详细对比

### 模块文档
- [DESIGN.md](docs/DESIGN.md) - 策略与风控设计说明
- [TRADE_FILTERS.md](docs/TRADE_FILTERS.md) - 交易过滤器模块文档

### 开发文档
- [PR_REVIEW_CHECKLIST.md](docs/PR_REVIEW_CHECKLIST.md) - 代码审查清单
- [.cursorrules](.cursorrules) - Cursor AI 开发规则
- [.codex/review.md](.codex/review.md) - Codex 代码审查提示

