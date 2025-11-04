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

## 开发规范

本项目配置了 Cursor AI 辅助开发规则（`.cursorrules`）和 Codex Cloud 代码审查提示（`.codex/review.md`），确保：
- 模块职责单一（策略/风控/执行分层）
- 无重绘指标，参数集中管理
- 交易前风控验证（点差、止损、时段、步进）
- 严格的订单处理和日志记录
- 基于风险占比的仓位计算
- 代码可测试性和可复现性

## 文档

- [DESIGN.md](docs/DESIGN.md) - 策略与风控设计说明
- [PR_REVIEW_CHECKLIST.md](docs/PR_REVIEW_CHECKLIST.md) - 代码审查清单
- [.cursorrules](.cursorrules) - Cursor AI 开发规则
- [.codex/review.md](.codex/review.md) - Codex 代码审查提示

