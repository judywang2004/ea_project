#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
交易过滤器配置验证脚本
用于验证 trade_filters 配置的合理性
"""

import json
from datetime import datetime, timedelta
import sys

def load_config(config_path='../config/params.default.json'):
    """加载配置文件"""
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"❌ 配置文件不存在: {config_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ 配置文件JSON格式错误: {e}")
        sys.exit(1)

def validate_filters_config(config):
    """验证过滤器配置"""
    errors = []
    warnings = []
    
    if 'filters' not in config:
        errors.append("缺少 'filters' 配置节")
        return errors, warnings
    
    filters = config['filters']
    
    # 1. 检查点差配置
    if filters.get('spread_filter_enabled', False):
        max_spread = filters.get('max_spread_points', 0)
        if max_spread <= 0:
            errors.append("max_spread_points 必须大于0")
        elif max_spread > 100:
            warnings.append(f"max_spread_points={max_spread} 可能过大")
        
        multiplier = filters.get('normal_spread_multiplier', 0)
        if multiplier < 1.5:
            warnings.append(f"normal_spread_multiplier={multiplier} 可能过小，建议>=2.0")
        elif multiplier > 5.0:
            warnings.append(f"normal_spread_multiplier={multiplier} 可能过大")
    
    # 2. 检查ATR配置
    if filters.get('volatility_filter_enabled', False):
        atr_period = filters.get('atr_period', 0)
        if atr_period <= 0:
            errors.append("atr_period 必须大于0")
        elif atr_period < 10:
            warnings.append(f"atr_period={atr_period} 可能过小，建议>=14")
        
        min_atr = filters.get('min_atr_value', 0)
        max_atr = filters.get('max_atr_value', 0)
        
        if min_atr <= 0:
            errors.append("min_atr_value 必须大于0")
        if max_atr <= 0:
            errors.append("max_atr_value 必须大于0")
        if min_atr >= max_atr:
            errors.append("min_atr_value 必须小于 max_atr_value")
    
    # 3. 检查假日配置
    if filters.get('holiday_filter_enabled', False):
        holidays = filters.get('holidays', [])
        if not holidays:
            warnings.append("假日列表为空，建议添加主要假日")
        else:
            # 验证日期格式
            for holiday in holidays:
                try:
                    datetime.strptime(holiday, '%Y-%m-%d')
                except ValueError:
                    errors.append(f"假日日期格式错误: {holiday} (应为 YYYY-MM-DD)")
            
            # 检查是否包含当年假日
            current_year = datetime.now().year
            has_current_year = any(holiday.startswith(str(current_year)) for holiday in holidays)
            if not has_current_year:
                warnings.append(f"假日列表中没有{current_year}年的假日，请更新")
    
    # 4. 检查交易时段配置
    if 'trading_hours' in config:
        hours = config['trading_hours']
        
        friday_close = hours.get('friday_close_hour', 0)
        monday_open = hours.get('monday_open_hour', 0)
        
        if friday_close < 0 or friday_close > 23:
            errors.append(f"friday_close_hour={friday_close} 超出范围 [0-23]")
        if monday_open < 0 or monday_open > 23:
            errors.append(f"monday_open_hour={monday_open} 超出范围 [0-23]")
        
        if friday_close < 18:
            warnings.append(f"friday_close_hour={friday_close} 较早，可能错过周五交易机会")
        
        # 检查新闻避开时间
        if filters.get('news_filter_enabled', False):
            before = hours.get('news_avoid_minutes_before', 0)
            after = hours.get('news_avoid_minutes_after', 0)
            
            if before < 0:
                errors.append("news_avoid_minutes_before 不能为负数")
            if after < 0:
                errors.append("news_avoid_minutes_after 不能为负数")
            
            if before < 15:
                warnings.append(f"news_avoid_minutes_before={before} 可能过短，建议>=30")
            if after < 15:
                warnings.append(f"news_avoid_minutes_after={after} 可能过短，建议>=30")
    
    return errors, warnings

def check_holiday_coverage(config):
    """检查假日覆盖范围"""
    if 'filters' not in config or not config['filters'].get('holidays'):
        return
    
    holidays = config['filters']['holidays']
    
    # 常见假日列表（美国）
    common_holidays = {
        'New Year': '01-01',
        'Independence Day': '07-04',
        'Thanksgiving': '11-28',  # 近似
        'Christmas': '12-25'
    }
    
    print("\n📅 假日覆盖检查:")
    current_year = datetime.now().year
    
    for name, date in common_holidays.items():
        full_date = f"{current_year}-{date}"
        if full_date in holidays:
            print(f"  ✓ {name} ({full_date})")
        else:
            print(f"  ⚠ {name} ({full_date}) 未配置")

def suggest_parameters(config):
    """参数建议"""
    print("\n💡 参数建议:")
    
    filters = config.get('filters', {})
    
    suggestions = []
    
    # 根据启用的过滤器给建议
    if filters.get('spread_filter_enabled', False):
        suggestions.append("点差过滤已启用：建议根据交易品种调整 max_spread_points")
        suggestions.append("  - 主要货币对（EURUSD, GBPUSD）: 20-30点")
        suggestions.append("  - 交叉盘: 30-50点")
        suggestions.append("  - 黄金: 50-100点")
    
    if filters.get('volatility_filter_enabled', False):
        suggestions.append("波动过滤已启用：ATR阈值应根据品种和时间周期调整")
        suggestions.append("  - 建议先运行一段时间，统计正常ATR范围")
        suggestions.append("  - 可以使用历史数据优化 min_atr 和 max_atr")
    
    if filters.get('news_filter_enabled', False):
        suggestions.append("新闻过滤已启用：建议使用外部新闻日历API")
        suggestions.append("  - ForexFactory Calendar")
        suggestions.append("  - Investing.com Economic Calendar")
    
    for suggestion in suggestions:
        print(f"  {suggestion}")

def main():
    print("=" * 60)
    print("交易过滤器配置验证")
    print("=" * 60)
    
    # 加载配置
    config = load_config()
    print("✓ 配置文件加载成功\n")
    
    # 验证配置
    errors, warnings = validate_filters_config(config)
    
    # 显示结果
    if errors:
        print("❌ 发现配置错误:")
        for error in errors:
            print(f"  • {error}")
        print()
    
    if warnings:
        print("⚠️  配置警告:")
        for warning in warnings:
            print(f"  • {warning}")
        print()
    
    if not errors and not warnings:
        print("✅ 配置验证通过！\n")
    
    # 假日覆盖检查
    if config.get('filters', {}).get('holiday_filter_enabled', False):
        check_holiday_coverage(config)
    
    # 参数建议
    suggest_parameters(config)
    
    # 显示当前启用的过滤器
    print("\n🔧 当前启用的过滤器:")
    filters = config.get('filters', {})
    filter_names = {
        'weekend_filter_enabled': '周末过滤',
        'holiday_filter_enabled': '假日过滤',
        'news_filter_enabled': '新闻过滤',
        'spread_filter_enabled': '点差过滤',
        'volatility_filter_enabled': '波动过滤'
    }
    
    for key, name in filter_names.items():
        status = "✓ 启用" if filters.get(key, False) else "✗ 禁用"
        print(f"  {name}: {status}")
    
    # 返回错误码
    sys.exit(1 if errors else 0)

if __name__ == '__main__':
    main()

