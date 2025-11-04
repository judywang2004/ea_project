# 指标模块

此目录包含自定义指标实现。

## 要求

⚠️ **重要：所有指标必须避免重绘**

### 正确写法（固定缓冲）

```mql4
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int limit = rates_total - prev_calculated;
    if(prev_calculated > 0) limit++;
    
    for(int i = limit - 1; i >= 0; i--) {
        // 计算指标值，只处理新 bar
        buffer[i] = CalculateValue(i);
    }
    
    return(rates_total);
}
```

### 文档要求

每个指标文件必须包含：
- 功能说明
- 是否有未来函数：**是/否**
- 是否会重绘：**是/否**
- 使用示例

## 示例文件结构

```
indicators/
├─ custom_ma.mq4             # 自定义移动平均
├─ atr_band.mq4              # ATR 通道
└─ volatility_index.mq4      # 波动率指标
```

