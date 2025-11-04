# 工具模块

此目录包含通用工具函数。

## 职责

- 时间过滤（交易时段、DST）
- 点值计算（3/5 位小数兼容）
- 点差检查
- 日志记录
- 品种信息获取

## 示例文件结构

```
utils/
├─ logger.mqh                # 日志工具
├─ time_filter.mqh           # 时间过滤
├─ symbol_info.mqh           # 品种信息
└─ helpers.mqh               # 辅助函数
```

