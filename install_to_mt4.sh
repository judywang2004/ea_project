#!/bin/bash
# MT4 EA自动安装脚本

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "========================================="
echo "  EA Project 自动安装脚本"
echo "========================================="
echo ""

# 默认MT4数据文件夹路径
DEFAULT_MT4_DIR="/Users/judywang/Library/Application Support/MetaTrader 4/Bottles/metatrader64/drive_c/Program Files (x86)/MetaTrader 4"

echo "${YELLOW}MT4数据文件夹路径:${NC}"
echo "默认路径: ${GREEN}$DEFAULT_MT4_DIR${NC}"
echo ""
echo "按回车使用默认路径，或输入自定义路径："
read -p "MT4数据文件夹 [默认]: " MT4_DATA_DIR

# 如果用户没输入，使用默认路径
if [ -z "$MT4_DATA_DIR" ]; then
    MT4_DATA_DIR="$DEFAULT_MT4_DIR"
    echo "${GREEN}使用默认路径${NC}"
fi

# 验证路径
if [ ! -d "$MT4_DATA_DIR" ]; then
    echo "${RED}❌ 错误: 路径不存在: $MT4_DATA_DIR${NC}"
    exit 1
fi

if [ ! -d "$MT4_DATA_DIR/MQL4" ]; then
    echo "${RED}❌ 错误: 这不是有效的MT4数据文件夹（缺少MQL4目录）${NC}"
    exit 1
fi

echo ""
echo "${GREEN}✓ MT4数据文件夹验证成功${NC}"
echo ""

# 创建必要的目录
echo "正在创建目录结构..."
mkdir -p "$MT4_DATA_DIR/MQL4/Experts"
mkdir -p "$MT4_DATA_DIR/MQL4/Scripts"
mkdir -p "$MT4_DATA_DIR/MQL4/Include/strategies"
mkdir -p "$MT4_DATA_DIR/MQL4/Include/risk"

# 复制文件
echo "正在复制文件..."

# 复制EA主文件
if [ -f "src/strategies/PyramidTrend_EA.mq4" ]; then
    cp "src/strategies/PyramidTrend_EA.mq4" "$MT4_DATA_DIR/MQL4/Experts/"
    echo "${GREEN}✓ 复制 PyramidTrend_EA.mq4${NC}"
else
    echo "${RED}✗ 找不到 PyramidTrend_EA.mq4${NC}"
fi

# 复制策略模块
if [ -f "src/strategies/pyramid_trend.mqh" ]; then
    cp "src/strategies/pyramid_trend.mqh" "$MT4_DATA_DIR/MQL4/Include/strategies/"
    echo "${GREEN}✓ 复制 pyramid_trend.mqh${NC}"
else
    echo "${RED}✗ 找不到 pyramid_trend.mqh${NC}"
fi

# 复制过滤器模块
if [ -f "src/risk/trade_filters.mqh" ]; then
    cp "src/risk/trade_filters.mqh" "$MT4_DATA_DIR/MQL4/Include/risk/"
    echo "${GREEN}✓ 复制 trade_filters.mqh${NC}"
else
    echo "${RED}✗ 找不到 trade_filters.mqh${NC}"
fi

# 复制示例EA（可选）
if [ -f "src/risk/trade_filters_example.mq4" ]; then
    cp "src/risk/trade_filters_example.mq4" "$MT4_DATA_DIR/MQL4/Experts/"
    echo "${GREEN}✓ 复制 trade_filters_example.mq4 (示例)${NC}"
fi

# 复制工具脚本
echo ""
echo "正在复制工具脚本..."
if [ -f "scripts/check_mt4_timezone.mq4" ]; then
    cp "scripts/check_mt4_timezone.mq4" "$MT4_DATA_DIR/MQL4/Scripts/"
    echo "${GREEN}✓ 复制 check_mt4_timezone.mq4 (时区检查工具)${NC}"
else
    echo "${RED}✗ 找不到 check_mt4_timezone.mq4${NC}"
fi

if [ -f "scripts/mark_nfp_times.mq4" ]; then
    cp "scripts/mark_nfp_times.mq4" "$MT4_DATA_DIR/MQL4/Scripts/"
    echo "${GREEN}✓ 复制 mark_nfp_times.mq4 (NFP标记工具)${NC}"
else
    echo "${RED}✗ 找不到 mark_nfp_times.mq4${NC}"
fi

echo ""
echo "${GREEN}=========================================${NC}"
echo "${GREEN}✓ 安装完成！${NC}"
echo "${GREEN}=========================================${NC}"
echo ""
echo "下一步："
echo "1. 打开MT4的MetaEditor (按F4)"
echo "2. 编译以下文件 (按F7):"
echo "   - Experts/PyramidTrend_EA.mq4"
echo "   - Scripts/check_mt4_timezone.mq4"
echo "   - Scripts/mark_nfp_times.mq4"
echo ""
echo "3. 使用方法："
echo "   【EA使用】"
echo "   - 在导航器 → EA交易 → PyramidTrend_EA"
echo "   - 拖到图表上开始交易"
echo ""
echo "   【时区检查】"
echo "   - 在导航器 → Scripts → check_mt4_timezone"
echo "   - 拖到任意图表上，查看Journal输出"
echo ""
echo "   【NFP标记】"
echo "   - 在导航器 → Scripts → mark_nfp_times"
echo "   - 拖到EURUSD H1图表上，选择时区"
echo "   - 会在图表上绘制黄色NFP时间线"
echo ""
echo "安装位置："
echo "  - EA文件: $MT4_DATA_DIR/MQL4/Experts/"
echo "  - 脚本文件: $MT4_DATA_DIR/MQL4/Scripts/"
echo "  - 策略模块: $MT4_DATA_DIR/MQL4/Include/strategies/"
echo "  - 过滤器模块: $MT4_DATA_DIR/MQL4/Include/risk/"
echo ""

