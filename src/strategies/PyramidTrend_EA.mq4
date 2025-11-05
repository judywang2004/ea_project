//+------------------------------------------------------------------+
//|                                           PyramidTrend_EA.mq4    |
//|                                       趋势金字塔EA - 机构级实现    |
//+------------------------------------------------------------------+
#property copyright "EA Project - Institutional Grade"
#property link      "https://github.com/judywang2004/ea_project"
#property version   "1.00"
#property strict

// 包含过滤器和策略模块
// Use < > for files in Include folder, relative to MQL4/Include/
#include <risk/trade_filters.mqh>
#include <strategies/pyramid_trend.mqh>

//+------------------------------------------------------------------+
//| Global Parameters
//+------------------------------------------------------------------+
input string  Section1 = "=== Basic Settings ===";    // Section divider
// EA魔术号
input int     MagicNumber = 88888;                    // Magic Number
// 订单备注
input string  TradeComment = "Pyramid";               // Trade Comment

input string  Section2 = "=== Filter Switches ===";   // Section divider
// 启用过滤器
input bool    EnableFilters = true;                   // Enable Filters
// 启用周末过滤
input bool    EnableWeekendFilter = true;             // Enable Weekend Filter
// 启用点差过滤
input bool    EnableSpreadFilter = true;              // Enable Spread Filter
// 启用波动过滤
input bool    EnableVolatilityFilter = true;          // Enable Volatility Filter

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   Print("================================================");
   Print("    Pyramid Trend EA Started - Institutional Grade");  // 趋势金字塔EA启动
   Print("================================================");
   Print("Symbol: ", Symbol());         // 交易品种
   Print("Timeframe: ", Period());      // 时间周期
   Print("Balance: $", AccountBalance());  // 账户余额
   Print("================================================");
   
   // 1. 初始化过滤器
   if(EnableFilters) {
      InitTradeFilters();
   } else {
      Print("[Warning] Filters disabled!");  // 警告：过滤器已禁用
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
      case REASON_PROGRAM:     reason_text = "EA terminated"; break;          // EA被终止
      case REASON_REMOVE:      reason_text = "EA removed from chart"; break;  // EA从图表移除
      case REASON_RECOMPILE:   reason_text = "EA recompiled"; break;          // EA重新编译
      case REASON_CHARTCHANGE: reason_text = "Chart symbol/period changed"; break; // 图表品种或周期改变
      case REASON_CHARTCLOSE:  reason_text = "Chart closed"; break;           // 图表关闭
      case REASON_PARAMETERS:  reason_text = "Parameters modified"; break;    // 参数修改
      case REASON_ACCOUNT:     reason_text = "Account switched"; break;       // 账户切换
      default:                 reason_text = "Unknown reason"; break;         // 未知原因
   }
   
   // 清理图表对象
   CleanupChartObjects();
   
   Print("================================================");
   Print("Pyramid Trend EA stopped");  // 趋势金字塔EA停止运行
   Print("Reason: ", reason_text);     // 停止原因
   Print("Final Balance: $", AccountBalance());  // 最终余额
   Print("Total Profit: $", AccountProfit());    // 总盈利
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
   Print("--- Trend Parameters ---");  // 趋势识别参数
   Print("  Fast EMA: ", TrendMA_Fast);
   Print("  Slow EMA: ", TrendMA_Slow);
   Print("  Filter EMA: ", TrendMA_Filter);
   Print("  ADX Period: ", ADX_Period, " | Threshold: ", ADX_Threshold);
   
   Print("--- Pyramid Parameters ---");  // 金字塔参数
   Print("  Max Levels: ", MaxPyramidLevels);
   Print("  Pyramid Ratio: ", PyramidRatio);
   Print("  Min Profit Points: ", MinProfitPointsToAdd);
   Print("  Price Distance: ", PriceDistanceMultiplier, " x ATR");
   
   Print("--- Risk Management ---");  // 风险管理
   Print("  Initial Risk: ", InitialRiskPercent, "%");
   Print("  Max Total Risk: ", MaxTotalRiskPercent, "%");
   Print("  Trail Stop: ", TrailStopATRMultiplier, " x ATR");
   Print("  Break-Even: ", UseBreakEvenStop ? "ON" : "OFF");
   
   Print("--- Exit Rules ---");  // 退出规则
   Print("  Exit on Reversal: ", ExitOnTrendReverse ? "ON" : "OFF");
   Print("  Partial TP: ", UsePartialTakeProfit ? "ON" : "OFF");
   if(UsePartialTakeProfit) {
      Print("    Ratio: ", PartialTP_Percent*100, "% | R:R: ", PartialTP_RR);
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
      Print("[Warning] Disconnected from server!");  // 与服务器断开连接
      return;
   }
   
   if(!IsTradeAllowed()) {
      Print("[Warning] EA trading not enabled! Check settings.");  // EA交易未启用
      return;
   }
}

//+------------------------------------------------------------------+

