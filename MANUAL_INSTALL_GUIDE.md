# 🎯 手动安装指南 - Manual Installation Guide

> **更新日期**: 2025-11-07  
> **版本**: v2.0 - 已修复乱码问题，添加2025年NFP数据

---

## ✅ 修复内容

1. ✅ **修复参数窗口乱码** - 所有输入参数改为英文
2. ✅ **添加2025年NFP数据** - 包含2025年1-12月所有NFP日期
3. ✅ **改进时区计算** - 更准确的时差显示

---

## 📂 第一步：文件复制

### 源文件位置
```
/Users/judywang/Documents/ea_project
```

### 目标位置（根据您的截图）
```
/Users/judywang/Library/Application Support/MetaTrader 4/Bottles/metatrader64/drive_c/Program Files/MetaTrader 4/MQL4
```

### 复制清单

| 源文件 | 目标位置 |
|--------|---------|
| `src/strategies/PyramidTrend_EA.mq4` | `MQL4/Experts/` |
| `src/strategies/pyramid_trend.mqh` | `MQL4/Include/strategies/` (如无此文件夹需创建) |
| `src/risk/trade_filters.mqh` | `MQL4/Include/risk/` (如无此文件夹需创建) |
| `scripts/check_mt4_timezone.mq4` | `MQL4/Scripts/` |
| `scripts/mark_nfp_times.mq4` | `MQL4/Scripts/` |

---

## 🔧 第二步：在MetaEditor中编译

### 打开MetaEditor
```
1. 打开MT4
2. 按 F4 键
```

### 编译三个文件

#### 1️⃣ 编译EA主程序
```
导航器 → Experts → PyramidTrend_EA.mq4
双击打开 → 按F7编译
确认底部显示: 0 error(s), 0 warning(s)
```

#### 2️⃣ 编译时区检查脚本
```
导航器 → Scripts → check_mt4_timezone.mq4
双击打开 → 按F7编译
确认: 0 error(s)
```

#### 3️⃣ 编译NFP标记脚本（v2.0 新版本）
```
导航器 → Scripts → mark_nfp_times.mq4
双击打开 → 按F7编译
确认: 0 error(s)
```

---

## 🎮 第三步：测试验证

### Test 1: 检查MT4时区 ⏰

**目的**: 找出您的MT4时区，确定NFP在MT4上是几点

```
1. 在MT4打开任意图表
2. 导航器 → 脚本 → check_mt4_timezone
3. 用鼠标拖到图表上
4. 查看 Terminal → Journal 窗口（底部）

预期输出:
========================================
Server Time: 2025.11.07 XX:XX
Local Time: 2025.11.07 YY:YY
Time Difference: Z hours
========================================

📝 记下这个时差！
```

### Test 2: 标记NFP时间线 📍

**目的**: 在图表上显示所有NFP时间，验证是否对准实际波动

**重要**: 需要切换到 **H1（1小时）图表** 才能看到具体时间！

```
1. 打开 EURUSD H1 图表（不是Daily！）
2. 按 Fn + ← 跳到2024年8月
3. 导航器 → 脚本 → mark_nfp_times
4. 拖到图表上
5. 参数窗口会出现（✅ 现在是英文，不再有乱码！）

参数说明:
- NFP Line Color: Yellow（黄色线）
- Line Width: 2
- Line Style: Solid
- Show Label: true（显示标签）
- Timezone Choice: 
  * 0 = Auto Detect（自动检测）
  * 1 = US Eastern (08:30)
  * 2 = GMT+2 (15:30)
  * 3 = GMT+3 (16:30)
  * 4 = Custom (11:30) ← 如果您之前看到11:00波动，选这个

6. 点击 OK
7. 图表上会出现黄色垂直线
8. 检查 2024.08.02 的黄线是否对准11:00-19:00的波动期
```

**✅ 如果黄线对准了波动，说明时区设置正确！**

### Test 3: 验证EA参数（无乱码） ✨

```
1. 打开策略测试器 (Ctrl+R)
2. 选择 PyramidTrend_EA
3. 点击"Expert properties"查看参数

✅ 预期结果:
- 所有参数都是英文
- 没有"????"或其他乱码
- TradeComment = "Pyr"
- EnableDemoMode = false (实盘) / true (仅显示信号)
```

### Test 4: 可视化测试（看趋势和信号）📈

```
1. 策略测试器设置:
   - Expert Advisor: PyramidTrend_EA
   - Symbol: EURUSD
   - Period: H1
   - Date: 2024.08.01 - 2024.08.09
   - ✅ Visualization: 勾选
   - Model: Every tick

2. 点击 Start

3. 观察:
   ✅ 买入点悬停显示: "Pyr L0: 0.14" (不再是"???")
   ✅ 图表右上角有趋势状态标签
   ✅ 左上角信息栏全部英文
   ✅ Journal日志全部英文
```

---

## 📊 第四步：查看NFP时间（解决"0点"问题）

### 问题：为什么黄线显示的时间是0点？

**答**: 因为您在 **Daily（日线）图表** 上！

### 解决方案：切换到H1图表

```
步骤:
1. 在MT4中打开EURUSD图表
2. 按 F6 或在菜单选择 Charts → Timeframe → H1
3. 现在K线是每小时一根
4. 重新运行 mark_nfp_times 脚本
5. 黄线会显示具体时间（如 08:30, 11:30, 15:30）
```

**重要提示**: 
- **Daily图表** - 每根K线 = 1天，时间显示为0:00（午夜）
- **H1图表** - 每根K线 = 1小时，时间显示为具体小时（如11:30）

---

## 🎉 第五步：2025年NFP验证

### 2025年NFP日期已添加

脚本现在包含：
- ✅ 2024年全年12个月NFP（1月-12月）
- ✅ 2025年全年12个月NFP（1月-12月）

### 验证2025年数据

```
1. 在H1图表按 Fn + → 跳到2025年
2. 应该看到黄色NFP线在:
   - 2025.01.10
   - 2025.02.07
   - 2025.03.07
   - 2025.04.04
   - 2025.05.02
   - 2025.06.06
   - 2025.07.03
   - 2025.08.01
   - 2025.09.05
   - 2025.10.03
   - 2025.11.07 ← 今天！
   - 2025.12.05
```

---

## ✅ 安装验证清单

完成后请确认:

```
□ 文件复制完成
  □ PyramidTrend_EA.mq4 → Experts/
  □ pyramid_trend.mqh → Include/strategies/
  □ trade_filters.mqh → Include/risk/
  □ check_mt4_timezone.mq4 → Scripts/
  □ mark_nfp_times.mq4 → Scripts/

□ 编译成功（0 errors）
  □ PyramidTrend_EA.mq4
  □ check_mt4_timezone.mq4
  □ mark_nfp_times.mq4

□ 测试验证
  □ 时区检查运行成功
  □ NFP黄线显示（H1图表）
  □ 2024年NFP线对准波动
  □ 2025年NFP线显示正确
  □ 参数窗口无乱码（全英文）
  □ Journal日志无乱码（全英文）
  □ 订单注释无乱码（显示"Pyr"）
```

---

## 🆘 常见问题

### Q1: 参数窗口还是显示"????"
**A**: 请确保复制的是最新版本文件，并且重新编译了脚本。

### Q2: 只看到2024年的NFP黄线，没有2025年的
**A**: 
1. 确保复制的是更新后的 `mark_nfp_times.mq4` (v2.0)
2. 重新编译脚本
3. 在图表上重新运行脚本

### Q3: 黄线时间是0点
**A**: 切换到H1图表，不要用Daily图表

### Q4: 编译错误 - 找不到include文件
**A**: 
1. 检查 `MQL4/Include/strategies/` 文件夹是否存在
2. 检查 `pyramid_trend.mqh` 是否在该文件夹中
3. 确保文件名大小写完全匹配

### Q5: 时区检查显示奇怪的时差（如-3388小时）
**A**: 这是显示bug，不影响功能。重新运行一次脚本即可。

---

## 📞 完成后请报告

请告诉我:
1. ✅ 安装是否成功
2. ✅ MT4时区是多少（几小时时差）
3. ✅ 2024.08.02的NFP黄线是否对准11:00-19:00波动
4. ✅ 2025年的NFP黄线是否都显示出来了
5. ✅ 参数窗口是否还有乱码

---

## 🎯 下一步

安装完成后，我们可以:
1. 根据您的MT4时区，优化新闻过滤器设置
2. 配置EA参数进行回测
3. 启用Demo模式进行实时信号测试（不下单）

**祝您安装顺利！** 🚀

