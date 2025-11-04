# 风控模块

此目录包含风险管理和仓位计算相关代码。

## 职责

- 基于风险百分比计算手数
- 验证止损距离
- 检查点差、交易时段等风控条件
- 计算最大仓位限制

## 示例文件结构

```
risk/
├─ position_sizing.mqh       # 仓位计算
├─ risk_validator.mqh        # 风控验证
└─ exposure_manager.mqh      # 敞口管理
```

