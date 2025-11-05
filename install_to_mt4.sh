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

# 让用户输入MT4数据文件夹路径
echo "${YELLOW}请输入您的MT4数据文件夹路径:${NC}"
echo "（通常是: ~/Library/Application Support/MetaTrader 4/[经纪商名称]）"
echo ""
read -p "MT4数据文件夹: " MT4_DATA_DIR

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

echo ""
echo "${GREEN}=========================================${NC}"
echo "${GREEN}✓ 安装完成！${NC}"
echo "${GREEN}=========================================${NC}"
echo ""
echo "下一步："
echo "1. 重启MT4（或点击导航器的刷新按钮）"
echo "2. 在导航器 → EA交易 中找到 PyramidTrend_EA"
echo "3. 拖动到图表上开始使用"
echo ""
echo "安装位置："
echo "  - EA文件: $MT4_DATA_DIR/MQL4/Experts/"
echo "  - 策略模块: $MT4_DATA_DIR/MQL4/Include/strategies/"
echo "  - 过滤器模块: $MT4_DATA_DIR/MQL4/Include/risk/"
echo ""

