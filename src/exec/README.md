# 执行模块

此目录包含订单执行相关代码。

## 职责

- OrderSend 封装（含重试逻辑）
- 错误码处理
- OrderModify 管理
- 追踪止损（trailing stop）
- NFA/FIFO 兼容性处理

## 示例文件结构

```
exec/
├─ order_manager.mqh         # 订单管理器
├─ error_handler.mqh         # 错误处理
└─ trailing_stop.mqh         # 追踪止损
```

