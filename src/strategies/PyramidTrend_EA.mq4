//+------------------------------------------------------------------+
//|                                           PyramidTrend_EA.mq4    |
//|                                       趋势金字塔EA - 机构级实现    |
//+------------------------------------------------------------------+
#property copyright "EA Project - Institutional Grade"
#property link      "https://github.com/judywang2004/ea_project"
#property version   "1.00"
#property strict

// 包含过滤器和策略模块
#include "../risk/trade_filters.mqh"
#include "pyramid_trend.mqh"

//+------------------------------------------------------------------+
//| 全局参数                                                           |
//+------------------------------------------------------------------+
input string  Section1 = "====== 基本设置 ======";  // ------
input int     MagicNumber = 88888;                    // EA魔术号
input string  TradeComment = "金字塔趋势";             // 订单备注

input string  Section2 = "====== 过滤器开关 ======"; // ------
input bool    EnableFilters = true;                   // 启用过滤器
input bool    EnableWeekendFilter = true;             // 启用周末过滤
input bool    EnableSpreadFilter = true;              // 启用点差过滤
input bool    EnableVolatilityFilter = true;          // 启用波动过滤

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   Print("================================================");
   Print("    趋势金字塔EA启动 - Institutional Grade");
   Print("================================================");
   Print("交易品种: ", Symbol());
   Print("时间周期: ", Period());
   Print("账户余额: $", AccountBalance());
   Print("================================================");
   
   // 1. 初始化过滤器
   if(EnableFilters) {
      InitTradeFilters();
   } else {
      Print("[警告] 过滤器已禁用！");
   }
   
   // 2. 初始化金字塔策略
   InitPyramidStrategy();
   
   // 3. 显示参数
   DisplayParameters();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   string reason_text = "";
   
   switch(reason) {
      case REASON_PROGRAM:     reason_text = "EA被终止"; break;
      case REASON_REMOVE:      reason_text = "EA从图表移除"; break;
      case REASON_RECOMPILE:   reason_text = "EA重新编译"; break;
      case REASON_CHARTCHANGE: reason_text = "图表品种或周期改变"; break;
      case REASON_CHARTCLOSE:  reason_text = "图表关闭"; break;
      case REASON_PARAMETERS:  reason_text = "参数修改"; break;
      case REASON_ACCOUNT:     reason_text = "账户切换"; break;
      default:                 reason_text = "未知原因"; break;
   }
   
   Print("================================================");
   Print("趋势金字塔EA停止运行");
   Print("停止原因: ", reason_text);
   Print("最终余额: $", AccountBalance());
   Print("总盈利: $", AccountProfit());
   Print("================================================");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // =====================================
   // 1. 过滤器检查（如果启用）
   // =====================================
   if(EnableFilters) {
      FilterResult filter = CanTrade(Symbol());
      
      if(!filter.passed) {
         // 静默处理（不频繁打印），只在状态变化时提示
         static bool lastFilterPassed = true;
         if(lastFilterPassed) {
            Comment("⏸ 交易暂停: ", filter.reason);
            Print("[过滤器] ", filter.reason);
         }
         lastFilterPassed = false;
         
         // 过滤器未通过，不执行策略
         return;
      }
      
      static bool lastFilterPassedOK = false;
      if(!lastFilterPassedOK) {
         Comment("▶ 交易窗口开放");
         Print("[过滤器] ✓ 所有过滤器通过");
      }
      lastFilterPassedOK = true;
   }
   
   // =====================================
   // 2. 执行金字塔策略
   // =====================================
   PyramidStrategyOnTick(Symbol());
   
   // =====================================
   // 3. 更新屏幕显示
   // =====================================
   UpdateDisplay();
}

//+------------------------------------------------------------------+
//| 显示EA参数                                                         |
//+------------------------------------------------------------------+
void DisplayParameters() {
   Print("--- 趋势识别参数 ---");
   Print("  快速均线: EMA(", TrendMA_Fast, ")");
   Print("  慢速均线: EMA(", TrendMA_Slow, ")");
   Print("  过滤均线: EMA(", TrendMA_Filter, ")");
   Print("  ADX周期: ", ADX_Period, " | 阈值: ", ADX_Threshold);
   
   Print("--- 金字塔参数 ---");
   Print("  最大层数: ", MaxPyramidLevels);
   Print("  加仓比例: ", PyramidRatio);
   Print("  最小盈利点数: ", MinProfitPointsToAdd);
   Print("  加仓距离: ", PriceDistanceMultiplier, " x ATR");
   
   Print("--- 风险管理 ---");
   Print("  初始风险: ", InitialRiskPercent, "%");
   Print("  最大总风险: ", MaxTotalRiskPercent, "%");
   Print("  追踪止损: ", TrailStopATRMultiplier, " x ATR");
   Print("  盈亏平衡: ", UseBreakEvenStop ? "启用" : "禁用");
   
   Print("--- 退出规则 ---");
   Print("  趋势反转退出: ", ExitOnTrendReverse ? "启用" : "禁用");
   Print("  分批止盈: ", UsePartialTakeProfit ? "启用" : "禁用");
   if(UsePartialTakeProfit) {
      Print("    比例: ", PartialTP_Percent*100, "% | R:R: ", PartialTP_RR);
   }
}

//+------------------------------------------------------------------+
//| 更新屏幕显示                                                       |
//+------------------------------------------------------------------+
void UpdateDisplay() {
   string display = "\n";
   display += "╔═══════════════════════════════════════╗\n";
   display += "║   趋势金字塔EA - Institutional Grade  ║\n";
   display += "╠═══════════════════════════════════════╣\n";
   
   // 账户信息
   display += StringFormat("║ 账户余额: $%.2f\n", AccountBalance());
   display += StringFormat("║ 浮动盈亏: $%.2f\n", AccountProfit());
   display += StringFormat("║ 净值: $%.2f\n", AccountEquity());
   display += "╠═══════════════════════════════════════╣\n";
   
   // 策略状态
   display += "║ " + GetPyramidStatus() + "\n";
   display += "╠═══════════════════════════════════════╣\n";
   
   // 市场信息
   double spread = (SymbolInfoDouble(Symbol(), SYMBOL_ASK) - 
                    SymbolInfoDouble(Symbol(), SYMBOL_BID)) / 
                    SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   double atr = iATR(Symbol(), PERIOD_CURRENT, 14, 0);
   
   display += StringFormat("║ 点差: %.1f | ATR: %.5f\n", spread, atr);
   
   // 过滤器状态
   if(EnableFilters) {
      display += "║ 过滤器: " + GetFilterStatus(Symbol()) + "\n";
   }
   
   display += "╚═══════════════════════════════════════╝\n";
   
   Comment(display);
}

//+------------------------------------------------------------------+
//| OnTimer function (每秒触发一次，用于监控)                          |
//+------------------------------------------------------------------+
void OnTimer() {
   // 定期检查系统状态
   if(!IsConnected()) {
      Print("[警告] 与服务器断开连接！");
      return;
   }
   
   if(!IsTradeAllowed()) {
      Print("[警告] EA交易未启用！请检查设置。");
      return;
   }
}

//+------------------------------------------------------------------+

