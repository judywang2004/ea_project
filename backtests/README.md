# 回测目录

此目录存储回测相关文件。

## 目录结构

```
backtests/
├─ mt_settings/              # MT4/MT5 回测设置文件
│   ├─ EURUSD_H1.set
│   └─ GBPUSD_M15.set
└─ reports/                  # 回测报告输出
    ├─ 2025-11-01_EURUSD.html
    ├─ 2025-11-01_EURUSD.csv
    └─ charts/
```

## 使用说明

### 1. 准备回测设置

在 `mt_settings/` 中创建 .set 文件，包含：
- EA 参数配置
- 品种和时间框架
- 回测时间范围

### 2. 运行回测

1. 在 MT4/MT5 Strategy Tester 中加载 EA
2. 导入对应的 .set 文件
3. 运行回测

### 3. 导出报告

回测完成后：
```bash
python scripts/export_report.py backtests/reports/report.html backtests/reports/
```

### 4. 分析结果

查看生成的：
- CSV 文件（交易明细）
- 图表（权益曲线、回撤等）
- 统计指标

## 回测检查清单

- [ ] 风险限制是否生效（≤0.5%/trade）
- [ ] 最大回撤是否在限制内（≤10%）
- [ ] 订单日志是否完整
- [ ] 无异常大量订单
- [ ] 点差设置合理（接近实盘）
- [ ] Slippage 模拟开启

