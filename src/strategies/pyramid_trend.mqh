//+------------------------------------------------------------------+
//|                                              pyramid_trend.mqh   |
//|                              趋势金字塔加仓策略 - 机构级实现       |
//+------------------------------------------------------------------+
#property copyright "EA Project - Institutional Grade"
#property strict

//+------------------------------------------------------------------+
//| Strategy Parameters (loaded from config file)
//+------------------------------------------------------------------+
// === Trend Identification Parameters ===
input int     TrendMA_Fast = 20;              // Fast EMA Period
input int     TrendMA_Slow = 50;              // Slow EMA Period  
input int     TrendMA_Filter = 200;           // Long-term Filter EMA
input int     ADX_Period = 14;                // ADX Period
input double  ADX_Threshold = 20.0;           // ADX Threshold (relaxed from 25 to capture more opportunities)
// 多时间框架过滤
input bool    UseHigherTimeframe = true;      // Use Daily Trend Filter (RE-ENABLED with relaxed thresholds)
input int     HigherTimeframe = PERIOD_D1;    // Higher Timeframe (D1/W1/MN1)

// === Pyramid Addition Parameters ===
input int     MaxPyramidLevels = 4;           // Max Pyramid Levels
input double  PyramidRatio = 0.618;           // Pyramid Ratio (Fibonacci)
input double  MinProfitPointsToAdd = 50;     // Min Profit Points to Add
input double  PriceDistanceMultiplier = 1.5; // Price Distance Multiplier (x ATR)

// === Risk Management Parameters ===
input double  InitialRiskPercent = 0.5;       // Initial Risk Percent (default 0.5% per .cursorrules)
input double  MaxTotalRiskPercent = 2.0;      // Max Total Risk Percent (default <=2% per .cursorrules)
input double  InitialStopLossATRMultiplier = 4.5; // Initial Stop Loss ATR Multiplier (wider to survive healthy pullbacks)
input double  TrailStopATRMultiplier = 3.5;   // Trail Stop ATR Multiplier (Phase 1.1: relaxed from 2.5 to 3.5)
input bool    UseBreakEvenStop = true;        // Use Break Even Stop

// === Exit Rules Parameters ===
input bool    ExitOnTrendReverse = true;      // Exit on Trend Reverse
input bool    UsePartialTakeProfit = true;    // Use Partial Take Profit
input double  PartialTP_Percent = 0.3;        // Partial TP Percent (30%)
input double  PartialTP_RR = 2.0;             // Partial TP Risk:Reward Ratio

//+------------------------------------------------------------------+
//| Position Information Structure
//+------------------------------------------------------------------+
struct PyramidPosition {
   int      ticket;           // Order Ticket
   int      level;            // Pyramid Level (0=initial, 1-3=additions)
   double   openPrice;        // Open Price
   double   lots;             // Lot Size
   double   stopLoss;         // Stop Loss
   double   takeProfit;       // Take Profit
   datetime openTime;         // Open Time
   bool     isPartialClosed;  // Partial Close Flag
};

//+------------------------------------------------------------------+
//| Trend Signal Enumeration
//+------------------------------------------------------------------+
enum TrendSignal {
   TREND_NONE = 0,      // No Trend
   TREND_UP = 1,        // Uptrend
   TREND_DOWN = -1,     // Downtrend
   TREND_WEAK = 99      // Weak Trend
};

//+------------------------------------------------------------------+
//| Market State Enumeration (Phase 2.0: SuperTrend + ADX + DI)
//+------------------------------------------------------------------+
enum MarketState {
   MARKET_STRONG_UPTREND,      // Strong Uptrend (ADX>25, ST bullish, +DI>-DI)
   MARKET_WEAK_UPTREND,        // Weak Uptrend (ADX 20-25, ST bullish)
   MARKET_STRONG_DOWNTREND,    // Strong Downtrend (ADX>25, ST bearish, -DI>+DI)
   MARKET_WEAK_DOWNTREND,      // Weak Downtrend (ADX 20-25, ST bearish)
   MARKET_RANGING,             // Ranging Market (ADX<20 or unclear direction)
   MARKET_UNCERTAIN            // Uncertain (transition period)
};

//+------------------------------------------------------------------+
//| SuperTrend Result Structure
//+------------------------------------------------------------------+
struct SuperTrendResult {
   double upper_band;    // Upper band (for downtrend)
   double lower_band;    // Lower band (for uptrend)
   int    direction;     // 1=bullish, -1=bearish, 0=neutral
   double atr_value;     // ATR value used
};

//+------------------------------------------------------------------+
//| SuperTrend Parameters (Phase 2.0)
//+------------------------------------------------------------------+
input bool    UseSuperTrend = true;           // Use SuperTrend for Market State (Phase 2.0 Enhanced)
input int     SuperTrend_Period = 10;         // SuperTrend ATR Period
input double  SuperTrend_Multiplier = 3.0;    // SuperTrend ATR Multiplier

//+------------------------------------------------------------------+
//| Global Variables
//+------------------------------------------------------------------+
// 当前金字塔仓位数组
PyramidPosition g_positions[];              // Current pyramid positions array
// 当前金字塔层数
int             g_currentLevel = 0;         // Current pyramid level count
// 当前识别的趋势
TrendSignal     g_currentTrend = TREND_NONE; // Current identified trend
// 上次加仓价格
double          g_lastAddPrice = 0;         // Last add position price
// 上次信号时间(防止重复)
datetime        g_lastSignalTime = 0;       // Last signal time (prevent duplicates)

//+------------------------------------------------------------------+
//| 初始化策略                                                         |
//+------------------------------------------------------------------+
void InitPyramidStrategy() {
   Print("========================================");
   Print("Pyramid Trend Strategy - Institutional Grade");  // 趋势金字塔策略 - 机构级实现
   Print("========================================");
   Print("Trend: EMA(", TrendMA_Fast, ") vs EMA(", TrendMA_Slow, ") + EMA(", TrendMA_Filter, ")");  // 趋势识别
   Print("Strength: ADX(", ADX_Period, ") > ", ADX_Threshold);  // 趋势强度
   Print("Max Levels: ", MaxPyramidLevels);  // 最大层数
   Print("Pyramid Ratio: ", PyramidRatio);  // 加仓比例
   Print("Initial Risk: ", InitialRiskPercent, "%");  // 初始风险
   Print("Max Risk: ", MaxTotalRiskPercent, "%");  // 最大风险
   Print("========================================");
   
   ArrayResize(g_positions, 0);
   g_currentLevel = 0;
   g_currentTrend = TREND_NONE;
}

//+------------------------------------------------------------------+
//| 主策略逻辑 - 每个Tick调用                                          |
//+------------------------------------------------------------------+
void PyramidStrategyOnTick(string symbol) {
   // 1. 更新当前持仓状态
   UpdatePositionArray(symbol);
   
   // 2. 检查趋势
   TrendSignal trend = AnalyzeTrend(symbol);
   
   // 3. 可视化趋势（在图表上显示）
   DrawTrendIndicator(symbol, trend);
   
   // 4. 管理现有仓位
   if(g_currentLevel > 0) {
      ManageExistingPositions(symbol, trend);
   }
   
   // 5. 检查新入场机会
   if(g_currentLevel == 0) {
      CheckEntrySignal(symbol, trend);
   }
   
   // 6. 检查加仓机会
   if(g_currentLevel > 0 && g_currentLevel < MaxPyramidLevels) {
      CheckPyramidSignal(symbol, trend);
   }
}

//+------------------------------------------------------------------+
//| Demo模式 - 只显示信号，不真实下单                                  |
//+------------------------------------------------------------------+
void PyramidStrategyOnTick_DemoMode(string symbol) {
   // 1. 检查趋势
   TrendSignal trend = AnalyzeTrend(symbol);
   
   // 2. 可视化趋势（在图表上显示）
   DrawTrendIndicator(symbol, trend);
   
   // 3. 检查并显示入场信号（但不下单）
   CheckEntrySignal_DemoMode(symbol, trend);
}

//+------------------------------------------------------------------+
//| Demo模式 - 检查入场信号（只显示，不下单）                          |
//+------------------------------------------------------------------+
void CheckEntrySignal_DemoMode(string symbol, TrendSignal trend) {
   // 如果没有明确趋势，不触发
   if(trend != TREND_UP && trend != TREND_DOWN) {
      return;
   }
   
   // 防止同一根K线重复信号
   datetime currentBar = iTime(symbol, PERIOD_CURRENT, 0);
   if(currentBar == g_lastSignalTime) {
      return;
   }
   
   // 趋势刚刚形成或延续
   if(trend == g_currentTrend) {
      return; // 趋势未变，不重复提示
   }
   
   // 如果有反向趋势，先不入场（等待确认）
   if(trend != g_currentTrend && g_currentTrend != TREND_NONE) {
      return;
   }
   
   // 触发信号提示
   double price = (trend == TREND_UP) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                                         SymbolInfoDouble(symbol, SYMBOL_BID);
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double stopLossDistance = atr * TrailStopATRMultiplier;
   double lots = CalculateLotSize(symbol, stopLossDistance, InitialRiskPercent);
   
   // 在图表上画信号箭头
   string signalName = StringFormat("DemoSignal_%d", currentBar);
   if(ObjectFind(signalName) >= 0) {
      ObjectDelete(signalName);
   }
   
   int arrowCode = (trend == TREND_UP) ? 241 : 242;  // 买入/卖出箭头
   color arrowColor = (trend == TREND_UP) ? clrLime : clrRed;
   
   if(ObjectCreate(signalName, OBJ_ARROW, 0, currentBar, price)) {
      ObjectSet(signalName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSet(signalName, OBJPROP_COLOR, arrowColor);
      ObjectSet(signalName, OBJPROP_WIDTH, 3);
      ObjectSet(signalName, OBJPROP_BACK, false);
   }
   
   // 打印信号
   Print("[DEMO Signal] ", trend == TREND_UP ? "LONG" : "SHORT",
         " | Price:", price, " | Lots:", lots, " | SL Distance:", stopLossDistance,
         " | Risk:", InitialRiskPercent, "%");
   
   g_lastSignalTime = currentBar;
   g_currentTrend = trend;
}

//+------------------------------------------------------------------+
//| 计算 SuperTrend 指标 (Phase 2.0 - 简化版，无缓存)
//+------------------------------------------------------------------+
SuperTrendResult CalculateSuperTrend(string symbol, int timeframe, int shift = 0) {
   SuperTrendResult result;
   
   // 获取当前K线数据
   double atr = iATR(symbol, timeframe, SuperTrend_Period, shift);
   double high = iHigh(symbol, timeframe, shift);
   double low = iLow(symbol, timeframe, shift);
   double close = iClose(symbol, timeframe, shift);
   
   result.atr_value = atr;
   
   // 计算基础上下轨
   double hl_avg = (high + low) / 2.0;
   double basic_upper = hl_avg + SuperTrend_Multiplier * atr;
   double basic_lower = hl_avg - SuperTrend_Multiplier * atr;
   
   // 简化版：只计算最近几根K线的SuperTrend
   // 足够用于判断当前趋势方向
   
   // 获取前一根K线数据（用于平滑）
   if(shift < iBars(symbol, timeframe) - 1) {
      double prev_atr = iATR(symbol, timeframe, SuperTrend_Period, shift + 1);
      double prev_high = iHigh(symbol, timeframe, shift + 1);
      double prev_low = iLow(symbol, timeframe, shift + 1);
      double prev_close = iClose(symbol, timeframe, shift + 1);
      
      double prev_hl_avg = (prev_high + prev_low) / 2.0;
      double prev_basic_upper = prev_hl_avg + SuperTrend_Multiplier * prev_atr;
      double prev_basic_lower = prev_hl_avg - SuperTrend_Multiplier * prev_atr;
      
      // 计算最终上下轨（带简单平滑）
      // 下轨（上升趋势支撑线）：只能上升不能下降
      double final_lower = (basic_lower > prev_basic_lower) ? basic_lower : prev_basic_lower;
      
      // 上轨（下降趋势阻力线）：只能下降不能上升  
      double final_upper = (basic_upper < prev_basic_upper) ? basic_upper : prev_basic_upper;
      
      // 检查趋势转换
      if(prev_close > prev_basic_upper) {
         // 前一根突破上轨 → 转为上升趋势
         final_lower = basic_lower;
         result.lower_band = final_lower;
         result.upper_band = basic_upper;  // 上轨不用于当前判断
      } else if(prev_close < prev_basic_lower) {
         // 前一根跌破下轨 → 转为下降趋势
         final_upper = basic_upper;
         result.lower_band = basic_lower;  // 下轨不用于当前判断
         result.upper_band = final_upper;
      } else {
         // 继续之前的趋势
         result.lower_band = final_lower;
         result.upper_band = final_upper;
      }
   } else {
      // 第一根K线
      result.lower_band = basic_lower;
      result.upper_band = basic_upper;
   }
   
   // 判断趋势方向
   if(close > result.lower_band) {
      result.direction = 1;   // 上升趋势（价格在下轨上方）
   } else if(close < result.upper_band) {
      result.direction = -1;  // 下降趋势（价格在上轨下方）
   } else {
      result.direction = 0;   // 中性（价格在上下轨之间）
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| 识别市场状态 (Phase 2.1: 简化为MA + ADX判断，禁用SuperTrend/DI)
//+------------------------------------------------------------------+
MarketState IdentifyMarketState(string symbol) {
   // === 使用前一根完成的Daily K线（更稳定可靠） ===
   double daily_close = iClose(symbol, PERIOD_D1, 1);
   
   // === 计算 Daily MA50 和 MA200 ===
   double daily_ma50 = iMA(symbol, PERIOD_D1, 50, 0, MODE_SMA, PRICE_CLOSE, 1);
   double daily_ma200 = iMA(symbol, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE, 1);
   
   // === 计算 Daily ADX（趋势强度） ===
   double daily_adx = iADX(symbol, PERIOD_D1, ADX_Period, PRICE_CLOSE, MODE_MAIN, 1);
   
   // === 趋势方向判断（基于MA位置关系） ===
   bool price_above_ma200 = (daily_close > daily_ma200);
   bool price_above_ma50 = (daily_close > daily_ma50);
   bool ma50_above_ma200 = (daily_ma50 > daily_ma200);  // 长期趋势向上
   
   // === 趋势强度判断 ===
   bool strong_trend = (daily_adx > 20.0);  // ADX > 20 = 有趋势
   
   // === 综合判断市场状态 ===
   
   // 上升趋势：严格要求 价格 > MA50 > MA200 + ADX > 20
   // 只在完全确认的上升趋势中做多
   if(price_above_ma50 && price_above_ma200 && ma50_above_ma200 && strong_trend) {
      Print("[Market] UPTREND confirmed - Close:", daily_close,
            " > MA50:", daily_ma50, " > MA200:", daily_ma200,
            " | ADX:", daily_adx);
      return MARKET_STRONG_UPTREND;
   }
   
   // 下降趋势：严格要求 价格 < MA50 < MA200 + ADX > 20
   // 只在完全确认的下降趋势中做空
   if(!price_above_ma50 && !price_above_ma200 && !ma50_above_ma200 && strong_trend) {
      Print("[Market] DOWNTREND confirmed - Close:", daily_close,
            " < MA50:", daily_ma50, " < MA200:", daily_ma200,
            " | ADX:", daily_adx);
      return MARKET_STRONG_DOWNTREND;
   }
   
   // 其他所有情况：震荡/过渡期/不确定（包括价格在MA之间）
   // 价格在MA50和MA200之间 = 趋势不明确 = 不交易
   string reason = "";
   if(price_above_ma200 && !price_above_ma50 && ma50_above_ma200) {
      reason = "Price between MAs (transition up)";
   } else if(!price_above_ma200 && price_above_ma50 && !ma50_above_ma200) {
      reason = "Price between MAs (transition down)";
   } else if(!strong_trend) {
      reason = "ADX too weak";
   } else {
      reason = "MA alignment unclear";
   }
   
   Print("[Market] RANGING/UNCERTAIN - ", reason,
         " | Close:", daily_close,
         " | MA50:", daily_ma50, " | MA200:", daily_ma200,
         " | ADX:", daily_adx);
   return MARKET_RANGING;
}

//+------------------------------------------------------------------+
//| 趋势分析 - 多重确认                                                |
//+------------------------------------------------------------------+
TrendSignal AnalyzeTrend(string symbol) {
   // 1. 计算均线
   double ema_fast = iMA(symbol, PERIOD_CURRENT, TrendMA_Fast, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_slow = iMA(symbol, PERIOD_CURRENT, TrendMA_Slow, 0, MODE_EMA, PRICE_CLOSE, 0);
   double ema_filter = iMA(symbol, PERIOD_CURRENT, TrendMA_Filter, 0, MODE_EMA, PRICE_CLOSE, 0);
   
   // 2. 计算ADX（趋势强度）
   double adx = iADX(symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
   double plus_di = iADX(symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, 0);
   double minus_di = iADX(symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, 0);
   
   // 3. 当前价格
   double price = SymbolInfoDouble(symbol, SYMBOL_BID);
   
   // 判断逻辑：多重确认
   bool strongTrend = adx > ADX_Threshold;
   
   // 4. 多时间框架过滤：检查日线趋势
   TrendSignal htfTrend = TREND_NONE;
   MarketState marketState = MARKET_UNCERTAIN;
   
   if(UseHigherTimeframe) {
      if(UseSuperTrend) {
         // Phase 2.0: 使用SuperTrend + ADX + DI识别市况
         marketState = IdentifyMarketState(symbol);
         
         // 将市况转换为趋势信号（用于兼容现有逻辑）
         if(marketState == MARKET_STRONG_UPTREND || marketState == MARKET_WEAK_UPTREND) {
            htfTrend = TREND_UP;
         } else if(marketState == MARKET_STRONG_DOWNTREND || marketState == MARKET_WEAK_DOWNTREND) {
            htfTrend = TREND_DOWN;
         } else {
            htfTrend = TREND_NONE;  // RANGING 或 UNCERTAIN 时不交易
         }
      } else {
         // 旧方法：使用MA过滤
         htfTrend = AnalyzeHigherTimeframeTrend(symbol);
      }
   }
   
   // 上升趋势：快线>慢线 + 价格>长期均线 + ADX强 + +DI>-DI
   if(ema_fast > ema_slow && price > ema_filter && strongTrend && plus_di > minus_di) {
      // 如果启用了高周期过滤，必须日线也是上升趋势
      if(UseHigherTimeframe && htfTrend != TREND_UP) {
         if(UseSuperTrend) {
            // Phase 2.0: SuperTrend 拒绝理由
            string state_name = "UNKNOWN";
            if(marketState == MARKET_RANGING) state_name = "RANGING";
            else if(marketState == MARKET_UNCERTAIN) state_name = "UNCERTAIN";
            else if(marketState == MARKET_STRONG_DOWNTREND) state_name = "STRONG DOWNTREND";
            else if(marketState == MARKET_WEAK_DOWNTREND) state_name = "WEAK DOWNTREND";
            
            Print("[Filter] H1 Uptrend detected but REJECTED by Daily SuperTrend filter");
            Print("[Filter] Daily market state: ", state_name);
            Print("[Filter] Required: STRONG_UPTREND or WEAK_UPTREND");
         } else {
            // Phase 1.1: MA 拒绝理由
            Print("[Filter] H1 Uptrend detected but REJECTED by Daily MA filter");
            Print("[Filter] Daily trend must be UP with all conditions met");
            Print("[Filter] Required: MA20>MA50>MA200, Price>MA200, MACD>0");
         }
         return TREND_NONE; // 日线不是上升趋势，拒绝
      }
      
      if(g_currentTrend != TREND_UP) {
         Print("[Strategy] Uptrend detected - EMA(", TrendMA_Fast, "):", ema_fast,  // 识别到上升趋势
               " > EMA(", TrendMA_Slow, "):", ema_slow, " | ADX:", adx,
               UseHigherTimeframe ? " | Daily: UP ✓" : "");
      }
      return TREND_UP;
   }
   
   // 下降趋势：快线<慢线 + 价格<长期均线 + ADX强 + -DI>+DI
   if(ema_fast < ema_slow && price < ema_filter && strongTrend && minus_di > plus_di) {
      // 如果启用了高周期过滤，必须日线也是下降趋势
      if(UseHigherTimeframe && htfTrend != TREND_DOWN) {
         if(UseSuperTrend) {
            // Phase 2.0: SuperTrend 拒绝理由
            string state_name = "UNKNOWN";
            if(marketState == MARKET_RANGING) state_name = "RANGING";
            else if(marketState == MARKET_UNCERTAIN) state_name = "UNCERTAIN";
            else if(marketState == MARKET_STRONG_UPTREND) state_name = "STRONG UPTREND";
            else if(marketState == MARKET_WEAK_UPTREND) state_name = "WEAK UPTREND";
            
            Print("[Filter] H1 Downtrend detected but REJECTED by Daily SuperTrend filter");
            Print("[Filter] Daily market state: ", state_name);
            Print("[Filter] Required: STRONG_DOWNTREND or WEAK_DOWNTREND");
         } else {
            // Phase 1.1: MA 拒绝理由
            Print("[Filter] H1 Downtrend detected but REJECTED by Daily MA filter");
            Print("[Filter] Daily trend must be DOWN with all conditions met");
            Print("[Filter] Required: MA20<MA50<MA200, Price<MA200, MACD<0");
         }
         return TREND_NONE; // 日线不是下降趋势，拒绝
      }
      
      if(g_currentTrend != TREND_DOWN) {
         Print("[Strategy] Downtrend detected - EMA(", TrendMA_Fast, "):", ema_fast,  // 识别到下降趋势
               " < EMA(", TrendMA_Slow, "):", ema_slow, " | ADX:", adx,
               UseHigherTimeframe ? " | Daily: DOWN ✓" : "");
      }
      return TREND_DOWN;
   }
   
   // 趋势减弱：ADX下降
   if(adx < ADX_Threshold && g_currentLevel > 0) {
      return TREND_WEAK;
   }
   
   return TREND_NONE;
}

//+------------------------------------------------------------------+
//| 分析高周期趋势（日线/周线）- Phase 1.1简化版（3层核心过滤）         |
//+------------------------------------------------------------------+
TrendSignal AnalyzeHigherTimeframeTrend(string symbol) {
   // === Phase 1.1改进：简化为3层核心过滤（平衡准确性和机会） ===
   
   // 1. 计算Daily均线（MA20, MA50, MA200）
   double htf_ma20 = iMA(symbol, HigherTimeframe, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
   double htf_ma50 = iMA(symbol, HigherTimeframe, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
   double htf_ma200 = iMA(symbol, HigherTimeframe, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
   double htf_price = iClose(symbol, HigherTimeframe, 0);
   
   // 2. 计算Daily MACD（趋势方向确认）
   double htf_macd_main = iMACD(symbol, HigherTimeframe, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
   
   // === 上升趋势判断（3层核心过滤）===
   bool uptrend_ma_alignment = (htf_ma20 > htf_ma50 && htf_ma50 > htf_ma200);  // Layer 1: MA排列正确
   bool uptrend_price_position = (htf_price > htf_ma200);                       // Layer 2: 价格在MA200上方
   bool uptrend_macd_positive = (htf_macd_main > 0);                            // Layer 3: MACD在零轴上方
   
   // 详细日志（用于调试）
   static datetime last_log_time = 0;
   datetime current_time = TimeCurrent();
   bool should_log = (current_time - last_log_time > 3600); // 每小时最多记录一次
   
   if(uptrend_ma_alignment && uptrend_price_position && uptrend_macd_positive) {
      if(should_log) {
         Print("[Daily Filter] UPTREND CONFIRMED - MA20:", htf_ma20, " > MA50:", htf_ma50, " > MA200:", htf_ma200,  // Daily上升趋势确认
               " | Price:", htf_price, " > MA200 | MACD:", htf_macd_main, " > 0");
         last_log_time = current_time;
      }
      return TREND_UP;
   }
   
   // === 下降趋势判断（3层核心过滤）===
   bool downtrend_ma_alignment = (htf_ma20 < htf_ma50 && htf_ma50 < htf_ma200);  // Layer 1: MA排列正确
   bool downtrend_price_position = (htf_price < htf_ma200);                       // Layer 2: 价格在MA200下方
   bool downtrend_macd_negative = (htf_macd_main < 0);                            // Layer 3: MACD在零轴下方
   
   if(downtrend_ma_alignment && downtrend_price_position && downtrend_macd_negative) {
      if(should_log) {
         Print("[Daily Filter] DOWNTREND CONFIRMED - MA20:", htf_ma20, " < MA50:", htf_ma50, " < MA200:", htf_ma200,  // Daily下降趋势确认
               " | Price:", htf_price, " < MA200 | MACD:", htf_macd_main, " < 0");
         last_log_time = current_time;
      }
      return TREND_DOWN;
   }
   
   // === 不满足条件 → 拒绝交易（带详细日志）===
   if(should_log) {
      string reason = "[Daily Filter] NO CLEAR TREND - ";  // Daily无明确趋势
      
      // 诊断具体原因
      if(!uptrend_ma_alignment && !downtrend_ma_alignment) {
         reason += "MA alignment unclear (MA20:" + DoubleToStr(htf_ma20, 5) + 
                   " MA50:" + DoubleToStr(htf_ma50, 5) + " MA200:" + DoubleToStr(htf_ma200, 5) + ") | ";  // MA排列不清晰
      }
      if(!uptrend_price_position && !downtrend_price_position) {
         reason += "Price near MA200 (Price:" + DoubleToStr(htf_price, 5) + 
                   " MA200:" + DoubleToStr(htf_ma200, 5) + ") | ";  // 价格接近MA200
      }
      if(MathAbs(htf_macd_main) < 0.0001) {
         reason += "MACD near zero (" + DoubleToStr(htf_macd_main, 6) + ") | ";  // MACD接近零轴
      }
      
      Print(reason);
      last_log_time = current_time;
   }
   
   return TREND_NONE;
}

//+------------------------------------------------------------------+
//| 检查初始入场信号                                                   |
//+------------------------------------------------------------------+
void CheckEntrySignal(string symbol, TrendSignal trend) {
   if(trend == TREND_NONE || trend == TREND_WEAK) return;
   
   // Phase 2.0: NFP冷静期（每月第一个周五15:00-17:00，延长到90分钟）
   int day_of_week = TimeDayOfWeek(TimeCurrent());
   int day_of_month = TimeDay(TimeCurrent());
   int hour = TimeHour(TimeCurrent());
   
   if(day_of_week == 5 && day_of_month <= 7 && (hour == 15 || hour == 16)) {
      Print("[NFP Filter] Cooling period (15:00-17:00) - Skip initial entry",
            " | Wait for 60-90 min after NFP for volatility to settle");
      return;
   }
   
   // 防止同一根K线重复信号
   datetime currentBar = iTime(symbol, PERIOD_CURRENT, 0);
   if(currentBar == g_lastSignalTime) return;
   
   // 确认趋势方向变化或新趋势
   if(trend != g_currentTrend && g_currentTrend != TREND_NONE) {
      // 之前有相反方向的趋势，先不入场（等待确认）
      return;
   }
   
   // 触发入场
   Print("[Signal] Initial entry signal - Direction:", trend == TREND_UP ? "LONG" : "SHORT");  // 初始入场信号
   
   ExecuteInitialEntry(symbol, trend);
   
   g_lastSignalTime = currentBar;
   g_currentTrend = trend;
}

//+------------------------------------------------------------------+
//| 执行初始入场                                                       |
//+------------------------------------------------------------------+
void ExecuteInitialEntry(string symbol, TrendSignal trend) {
   // 1. 计算ATR用于止损
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   
   // 2. 计算初始止损距离（使用更宽的倍数以避免被健康回调扫出）
   double stopLossDistance = atr * InitialStopLossATRMultiplier;
   
   // 3. 计算手数（基于风险百分比）
   double lots = CalculateLotSize(symbol, stopLossDistance, InitialRiskPercent);
   
   if(lots < SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN)) {
      Print("[Error] Calculated lot size too small:", lots);  // 计算手数过小
      return;
   }
   
   // 4. 执行开仓
   int orderType = (trend == TREND_UP) ? OP_BUY : OP_SELL;
   double price = (trend == TREND_UP) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                                         SymbolInfoDouble(symbol, SYMBOL_BID);
   
   double sl = (trend == TREND_UP) ? price - stopLossDistance : price + stopLossDistance;
   double tp = 0; // 不设固定TP，使用追踪止损
   
   int ticket = OrderSend(symbol, orderType, lots, price, 3, sl, tp, 
                         "金字塔L0", 12345, 0, 
                         trend == TREND_UP ? clrBlue : clrRed);
   
   if(ticket > 0) {
      Print("[Entry Success] Level 0 - Ticket:", ticket, " | Lots:", lots,  // 开仓成功
            " | SL Distance:", stopLossDistance, " | Risk:", InitialRiskPercent, "%");
      
      // 在图表上标记入场点
      DrawOrderMarker(symbol, ticket, price, trend, 0);
      
      // 添加到仓位数组
      AddPositionToArray(ticket, 0, price, lots, sl, tp);
      g_currentLevel = 1;
      g_lastAddPrice = price;
   } else {
      Print("[Entry Failed] Error code:", GetLastError());  // 开仓失败
   }
}

//+------------------------------------------------------------------+
//| 检查金字塔加仓信号                                                 |
//+------------------------------------------------------------------+
void CheckPyramidSignal(string symbol, TrendSignal trend) {
   // 1. 检查趋势是否一致
   if(trend != g_currentTrend) return;
   
   // 2. Phase 2.0: NFP冷静期（每月第一个周五15:00-17:00，延长到90分钟）
   int day_of_week = TimeDayOfWeek(TimeCurrent());
   int day_of_month = TimeDay(TimeCurrent());
   int hour = TimeHour(TimeCurrent());
   int minute = TimeMinute(TimeCurrent());
   
   // NFP通常在每月第一个周五 08:30 EDT发布 = 15:30 MT4 (GMT+3)
   // 冷静期：15:00-17:00（NFP前30分钟 + NFP后60-90分钟）
   if(day_of_week == 5 && day_of_month <= 7 && (hour == 15 || hour == 16)) {
      Print("[NFP Filter] Cooling period (15:00-17:00 on first Friday)",
            " | Skip pyramid to avoid NFP volatility",
            " | Wait 60-90 min after NFP for volatility to settle");
      return;
   }
   
   // 3. Phase 2.0: 检测Spike（急速上涨/下跌），避免追高/追低
   double current_bar_size = MathAbs(iClose(symbol, PERIOD_CURRENT, 0) - iOpen(symbol, PERIOD_CURRENT, 0));
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double spike_threshold = atr * 2.0;  // K线实体超过2倍ATR认为是spike
   
   if(current_bar_size > spike_threshold) {
      Print("[Spike Detected] Current bar size:", DoubleToStr(current_bar_size / SymbolInfoDouble(symbol, SYMBOL_POINT), 1), 
            " pips > 2×ATR:", DoubleToStr(spike_threshold / SymbolInfoDouble(symbol, SYMBOL_POINT), 1), 
            " pips | Skip pyramid add to avoid chasing");
      return;  // Spike中不加仓，避免追高
   }
   
   // 4. Phase 2.0: 价格距离限制 - 避免追高/追低（等待回调）
   double currentPrice = (trend == TREND_UP) ? 
       SymbolInfoDouble(symbol, SYMBOL_ASK) : 
       SymbolInfoDouble(symbol, SYMBOL_BID);
   
   double priceDiff = MathAbs(currentPrice - g_lastAddPrice);
   double maxAddDistance = atr * 1.5;  // 距离上次加仓超过1.5×ATR，等待回调（从2.0降低到1.5以更严格防止追高）
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(priceDiff > maxAddDistance) {
      Print("[Pullback Required] Price moved too far from last add: ", 
            DoubleToStr(priceDiff / point, 1), " pips",
            " > Max distance: ", DoubleToStr(maxAddDistance / point, 1), " pips",
            " | Last add: ", DoubleToStr(g_lastAddPrice, 5),
            " | Current: ", DoubleToStr(currentPrice, 5),
            " | Wait for healthy pullback before adding");
      return;
   }
   
   // 5. 检查第一单是否盈利
   if(ArraySize(g_positions) == 0) return;
   
   PyramidPosition firstPos = g_positions[0];
   if(!OrderSelect(firstPos.ticket, SELECT_BY_TICKET)) return;
   
   double currentProfit = OrderProfit();
   double profitPoints = MathAbs(OrderClosePrice() - OrderOpenPrice()) / SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(currentProfit <= 0 || profitPoints < MinProfitPointsToAdd) {
      return; // 第一单未达到盈利要求
   }
   
   // 6. 检查价格是否移动足够距离（最小距离要求）
   // 注意：步骤4已经检查了最大距离（避免追高），这里检查最小距离（确保趋势延续）
   double priceMove = MathAbs(currentPrice - g_lastAddPrice);
   double requiredMove = atr * PriceDistanceMultiplier;
   
   if(priceMove < requiredMove) {
      return; // 价格移动不足
   }
   
   // 7. 检查总风险是否超限
   double totalRisk = CalculateTotalRisk(symbol);
   if(totalRisk >= MaxTotalRiskPercent) {
      Print("[Risk Control] Total risk limit reached:", totalRisk, "% >= ", MaxTotalRiskPercent, "%");  // 总风险已达上限
      return;
   }
   
   // 8. 触发加仓
   Print("[Signal] Pyramid addition Level ", g_currentLevel, " - Profit pts:", profitPoints,  // 金字塔加仓
         " | Price move:", priceMove, " (Required:", requiredMove, ")");
   
   ExecutePyramidAdd(symbol, trend);
}

//+------------------------------------------------------------------+
//| 执行金字塔加仓                                                     |
//+------------------------------------------------------------------+
void ExecutePyramidAdd(string symbol, TrendSignal trend) {
   // 1. 计算加仓手数（递减）
   PyramidPosition lastPos = g_positions[ArraySize(g_positions) - 1];
   double newLots = NormalizeDouble(lastPos.lots * PyramidRatio, 2);
   
   if(newLots < SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN)) {
      Print("[Warning] Add lot size too small, stop adding");  // 加仓手数过小，停止加仓
      return;
   }
   
   // 2. 计算止损（使用更宽的初始止损倍数，与初始仓位相同逻辑）
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double stopLossDistance = atr * InitialStopLossATRMultiplier;
   
   int orderType = (trend == TREND_UP) ? OP_BUY : OP_SELL;
   double price = (trend == TREND_UP) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                                         SymbolInfoDouble(symbol, SYMBOL_BID);
   
   double sl = (trend == TREND_UP) ? price - stopLossDistance : price + stopLossDistance;
   
   // 3. 执行加仓
   int ticket = OrderSend(symbol, orderType, newLots, price, 3, sl, 0, 
                         StringFormat("金字塔L%d", g_currentLevel), 12345, 0, clrGreen);
   
   if(ticket > 0) {
      Print("[Add Success] Level ", g_currentLevel, " - Ticket:", ticket,  // 加仓成功
            " | Lots:", newLots, " (", PyramidRatio*100, "%)");
      
      // 在图表上标记加仓点
      DrawOrderMarker(symbol, ticket, price, g_currentTrend, g_currentLevel);
      
      AddPositionToArray(ticket, g_currentLevel, price, newLots, sl, 0);
      g_currentLevel++;
      g_lastAddPrice = price;
      
      // 更新所有仓位的止损（移动到盈亏平衡或追踪）
      UpdateAllStopLosses(symbol);
   } else {
      Print("[Add Failed] Error code:", GetLastError());  // 加仓失败
   }
}

//+------------------------------------------------------------------+
//| 管理现有仓位                                                       |
//+------------------------------------------------------------------+
void ManageExistingPositions(string symbol, TrendSignal trend) {
   // 1. 检查趋势反转 - 全部平仓
   if(ExitOnTrendReverse && trend != g_currentTrend && trend != TREND_NONE) {
      Print("[Exit] Trend reversal - Close all");  // 趋势反转 - 全部平仓
      CloseAllPyramidPositions(symbol, "Trend Reversal");
      return;
   }
   
   // 2. 检查趋势减弱 - 全部平仓
   if(trend == TREND_WEAK) {
      Print("[Exit] Trend weakening - Close all");  // 趋势减弱 - 全部平仓
      CloseAllPyramidPositions(symbol, "Trend Weakening");
      return;
   }
   
   // 3. 更新追踪止损
   UpdateAllStopLosses(symbol);
   
   // 4. 分批止盈
   if(UsePartialTakeProfit) {
      CheckPartialTakeProfit(symbol);
   }
}

//+------------------------------------------------------------------+
//| 辅助函数：检查Daily趋势是否仍然有效（方案C：多重时间框架确认）       |
//+------------------------------------------------------------------+
bool IsDailyTrendStillValid(string symbol, int orderType) {
   // Phase 2.0: 使用SuperTrend + ADX + DI检查Daily趋势
   if(UseSuperTrend) {
      // 使用新的SuperTrend市况识别
      MarketState state = IdentifyMarketState(symbol);
      
      if(orderType == OP_BUY) {
         // 做多：检查Daily是否仍然上升趋势（强或弱）
         return (state == MARKET_STRONG_UPTREND || state == MARKET_WEAK_UPTREND);
         
      } else if(orderType == OP_SELL) {
         // 做空：检查Daily是否仍然下降趋势（强或弱）
         return (state == MARKET_STRONG_DOWNTREND || state == MARKET_WEAK_DOWNTREND);
      }
      
   } else {
      // 旧方法：使用MA过滤（向后兼容）
      double daily_ma20 = iMA(symbol, PERIOD_D1, 20, 0, MODE_EMA, PRICE_CLOSE, 0);
      double daily_ma50 = iMA(symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE, 0);
      double daily_ma200 = iMA(symbol, PERIOD_D1, 200, 0, MODE_SMA, PRICE_CLOSE, 0);
      double daily_macd = iMACD(symbol, PERIOD_D1, 12, 26, 9, PRICE_CLOSE, MODE_MAIN, 0);
      double daily_price = iClose(symbol, PERIOD_D1, 0);
      
      if(orderType == OP_BUY) {
         // 做多：检查Daily是否仍然上升趋势
         bool ma_aligned = (daily_ma20 > daily_ma50 && daily_ma50 > daily_ma200);
         bool price_ok = (daily_price > daily_ma200);
         bool macd_ok = (daily_macd > 0);
         
         return (ma_aligned && price_ok && macd_ok);
         
      } else if(orderType == OP_SELL) {
         // 做空：检查Daily是否仍然下降趋势
         bool ma_aligned = (daily_ma20 < daily_ma50 && daily_ma50 < daily_ma200);
         bool price_ok = (daily_price < daily_ma200);
         bool macd_ok = (daily_macd < 0);
         
         return (ma_aligned && price_ok && macd_ok);
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| 更新所有仓位的追踪止损                                             |
//+------------------------------------------------------------------+
void UpdateAllStopLosses(string symbol) {
   // 使用静态变量控制更新频率（避免每个tick都修改）
   static datetime lastUpdateTime = 0;
   datetime currentBar = iTime(symbol, PERIOD_CURRENT, 0);
   
   // 只在新K线时更新止损（大幅减少修改次数）
   if(currentBar == lastUpdateTime) {
      return;
   }
   lastUpdateTime = currentBar;
   
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double trailDistance = atr * TrailStopATRMultiplier;
   double minStepPoints = 50; // 最小移动50点才修改（避免频繁小幅修改）
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   for(int i = 0; i < ArraySize(g_positions); i++) {
      if(!OrderSelect(g_positions[i].ticket, SELECT_BY_TICKET)) continue;
      if(OrderCloseTime() > 0) continue; // 已平仓
      
      double currentPrice = (OrderType() == OP_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : 
                                                       SymbolInfoDouble(symbol, SYMBOL_ASK);
      double currentSL = OrderStopLoss();
      double newSL = 0;
      
      if(OrderType() == OP_BUY) {
         // 做多：追踪止损向上移动
         newSL = currentPrice - trailDistance;
         
         // 盈亏平衡止损
         if(UseBreakEvenStop && currentPrice > OrderOpenPrice() + trailDistance) {
            double breakEvenSL = OrderOpenPrice() + 10 * point;
            if(newSL < breakEvenSL) newSL = breakEvenSL;
         }
         
         // 只在移动距离足够大时才修改（减少不必要的修改）
         if(newSL > currentSL && (newSL - currentSL) > minStepPoints * point) {
            // Phase 2.0优化：总是检查Daily趋势
            bool dailyTrendValid = IsDailyTrendStillValid(symbol, OP_BUY);
            double distanceToSL = (currentPrice - currentSL) / point;
            double trailPips = trailDistance / point;
            
            if(dailyTrendValid) {
               // Daily趋势仍然有效（UPTREND）
               if(distanceToSL < (3.0 * trailPips)) {
                  // 价格在3倍ATR内接近止损，可能是H1回调
                  // 不移动止损，给回调更多空间
                  Print("[Multi-TF Filter] Ticket:", OrderTicket(), " | Hold SL | Daily UPTREND valid ✓",
                        " | Dist:", DoubleToStr(distanceToSL, 1), " pips | 3×Trail:", DoubleToStr(3.0*trailPips, 1), " pips");
               } else {
                  // 价格远离止损，正常移动
                  if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrBlue)) {
                     Print("[SL Update] Ticket:", OrderTicket(), " | New SL:", newSL, 
                           " | Dist:", DoubleToStr(distanceToSL, 1), " pips | Daily: UP ✓");
                  }
               }
            } else {
               // Daily趋势已转弱/反转，收紧止损保护利润
               if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrBlue)) {
                  Print("[SL Update] Ticket:", OrderTicket(), " | New SL:", newSL, 
                        " | Dist:", DoubleToStr(distanceToSL, 1), " pips | Daily: WEAK/REVERSED ✗");
               }
            }
         }
      } else {
         // 做空：追踪止损向下移动
         newSL = currentPrice + trailDistance;
         
         if(UseBreakEvenStop && currentPrice < OrderOpenPrice() - trailDistance) {
            double breakEvenSL = OrderOpenPrice() - 10 * point;
            if(newSL > breakEvenSL) newSL = breakEvenSL;
         }
         
         // 只在移动距离足够大时才修改
         if((newSL < currentSL || currentSL == 0) && (currentSL == 0 || (currentSL - newSL) > minStepPoints * point)) {
            // Phase 2.0优化：总是检查Daily趋势
            bool dailyTrendValid = IsDailyTrendStillValid(symbol, OP_SELL);
            double distanceToSL = (currentSL - currentPrice) / point;
            double trailPips = trailDistance / point;
            
            if(dailyTrendValid) {
               // Daily趋势仍然有效（DOWNTREND）
               if(distanceToSL < (3.0 * trailPips)) {
                  // 价格在3倍ATR内接近止损，可能是H1回调
                  // 不移动止损，给回调更多空间
                  Print("[Multi-TF Filter] Ticket:", OrderTicket(), " | Hold SL | Daily DOWNTREND valid ✓",
                        " | Dist:", DoubleToStr(distanceToSL, 1), " pips | 3×Trail:", DoubleToStr(3.0*trailPips, 1), " pips");
               } else {
                  // 价格远离止损，正常移动
                  if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed)) {
                     Print("[SL Update] Ticket:", OrderTicket(), " | New SL:", newSL, 
                           " | Dist:", DoubleToStr(distanceToSL, 1), " pips | Daily: DOWN ✓");
                  }
               }
            } else {
               // Daily趋势已转弱/反转，收紧止损保护利润
               if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed)) {
                  Print("[SL Update] Ticket:", OrderTicket(), " | New SL:", newSL, 
                        " | Dist:", DoubleToStr(distanceToSL, 1), " pips | Daily: WEAK/REVERSED ✗");
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 检查分批止盈                                                       |
//+------------------------------------------------------------------+
void CheckPartialTakeProfit(string symbol) {
   for(int i = 0; i < ArraySize(g_positions); i++) {
      if(g_positions[i].isPartialClosed) continue;
      if(!OrderSelect(g_positions[i].ticket, SELECT_BY_TICKET)) continue;
      if(OrderCloseTime() > 0) continue;
      
      // 获取当前市场价格（修复：不使用OrderClosePrice，对未平仓订单为0）
      double currentPrice = (OrderType() == OP_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : 
                                                       SymbolInfoDouble(symbol, SYMBOL_ASK);
      
      // 计算风险回报比
      double profitPoints = MathAbs(currentPrice - OrderOpenPrice()) / SymbolInfoDouble(symbol, SYMBOL_POINT);
      double riskPoints = MathAbs(OrderOpenPrice() - g_positions[i].stopLoss) / SymbolInfoDouble(symbol, SYMBOL_POINT);
      
      if(riskPoints == 0) continue;
      
      double currentRR = profitPoints / riskPoints;
      
      // 达到目标RR，部分平仓
      if(currentRR >= PartialTP_RR) {
         double closeLots = NormalizeDouble(OrderLots() * PartialTP_Percent, 2);
         double closePrice = (OrderType() == OP_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : 
                                                        SymbolInfoDouble(symbol, SYMBOL_ASK);
         
         if(closeLots >= SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN)) {
            bool closed = OrderClose(OrderTicket(), closeLots, closePrice, 3, clrOrange);
            
            if(closed) {
               Print("[Partial TP] Ticket:", OrderTicket(), " | Closed:", closeLots, " lots (",  // 分批止盈
                     PartialTP_Percent*100, "%) | R:R=", currentRR);
               g_positions[i].isPartialClosed = true;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 平仓所有金字塔仓位                                                 |
//+------------------------------------------------------------------+
void CloseAllPyramidPositions(string symbol, string reason) {
   for(int i = 0; i < ArraySize(g_positions); i++) {
      if(!OrderSelect(g_positions[i].ticket, SELECT_BY_TICKET)) continue;
      if(OrderCloseTime() > 0) continue; // 已平仓
      
      // 获取正确的平仓价格（修复：不使用OrderClosePrice，对未平仓订单为0）
      double closePrice = (OrderType() == OP_BUY) ? SymbolInfoDouble(symbol, SYMBOL_BID) : 
                                                     SymbolInfoDouble(symbol, SYMBOL_ASK);
      
      bool closed = OrderClose(OrderTicket(), OrderLots(), closePrice, 5, clrYellow);
      
      if(closed) {
         Print("[Close] Ticket:", OrderTicket(), " | Level:", g_positions[i].level,  // 平仓
               " | Reason:", reason, " | Profit:", OrderProfit());
      }
   }
   
   // 重置状态
   ArrayResize(g_positions, 0);
   g_currentLevel = 0;
   g_currentTrend = TREND_NONE;
   g_lastAddPrice = 0;
}

//+------------------------------------------------------------------+
//| 计算手数（基于风险百分比）                                         |
//+------------------------------------------------------------------+
double CalculateLotSize(string symbol, double stopLossDistance, double riskPercent) {
   double accountBalance = AccountBalance();
   double riskAmount = accountBalance * riskPercent / 100.0;
   
   double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   double stopLossPoints = stopLossDistance / point;
   
   double lots = riskAmount / (stopLossPoints * tickValue);
   
   // 规范化手数
   double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| 计算当前总风险                                                     |
//+------------------------------------------------------------------+
double CalculateTotalRisk(string symbol) {
   double totalRisk = 0;
   
   for(int i = 0; i < ArraySize(g_positions); i++) {
      if(!OrderSelect(g_positions[i].ticket, SELECT_BY_TICKET)) continue;
      if(OrderCloseTime() > 0) continue;
      
      double stopLossDistance = MathAbs(OrderOpenPrice() - OrderStopLoss());
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      
      double riskAmount = (stopLossDistance / point) * tickValue * OrderLots();
      totalRisk += (riskAmount / AccountBalance()) * 100.0;
   }
   
   return totalRisk;
}

//+------------------------------------------------------------------+
//| 辅助函数：添加仓位到数组                                           |
//+------------------------------------------------------------------+
void AddPositionToArray(int ticket, int level, double price, double lots, double sl, double tp) {
   int size = ArraySize(g_positions);
   ArrayResize(g_positions, size + 1);
   
   g_positions[size].ticket = ticket;
   g_positions[size].level = level;
   g_positions[size].openPrice = price;
   g_positions[size].lots = lots;
   g_positions[size].stopLoss = sl;
   g_positions[size].takeProfit = tp;
   g_positions[size].openTime = TimeCurrent();
   g_positions[size].isPartialClosed = false;
}

//+------------------------------------------------------------------+
//| 辅助函数：更新仓位数组（移除已平仓）                               |
//+------------------------------------------------------------------+
void UpdatePositionArray(string symbol) {
   PyramidPosition temp[];
   int count = 0;
   
   for(int i = 0; i < ArraySize(g_positions); i++) {
      if(OrderSelect(g_positions[i].ticket, SELECT_BY_TICKET) && OrderCloseTime() == 0) {
         ArrayResize(temp, count + 1);
         temp[count] = g_positions[i];
         count++;
      }
   }
   
   ArrayFree(g_positions);
   ArrayResize(g_positions, count);
   
   for(int i = 0; i < count; i++) {
      g_positions[i] = temp[i];
   }
   
   // 更新当前层数
   if(count == 0) {
      g_currentLevel = 0;
   }
}

//+------------------------------------------------------------------+
//| 获取策略状态（用于监控）                                           |
//+------------------------------------------------------------------+
string GetPyramidStatus() {
   string status = StringFormat("Trend:%s | Level:%d/%d | Positions:%d",  // 趋势 | 层数 | 仓位数
                                g_currentTrend == TREND_UP ? "UP" : 
                                g_currentTrend == TREND_DOWN ? "DOWN" : "NONE",
                                g_currentLevel, MaxPyramidLevels,
                                ArraySize(g_positions));
   
   if(ArraySize(g_positions) > 0) {
      double totalProfit = 0;
      for(int i = 0; i < ArraySize(g_positions); i++) {
         if(OrderSelect(g_positions[i].ticket, SELECT_BY_TICKET)) {
            totalProfit += OrderProfit();
         }
      }
      status += StringFormat(" | Profit:$%.2f", totalProfit);  // 总盈利
   }
   
   return status;
}

//+------------------------------------------------------------------+
//| 可视化趋势指示器（在图表上显示）                                    |
//+------------------------------------------------------------------+
void DrawTrendIndicator(string symbol, TrendSignal trend) {
   // 获取ADX值
   double adx = iADX(symbol, PERIOD_CURRENT, ADX_Period, PRICE_CLOSE, MODE_MAIN, 0);
   
   // 使用静态变量减少更新频率
   static TrendSignal lastDrawnTrend = TREND_NONE;
   static datetime lastDrawnTime = 0;
   static int updateCounter = 0;
   datetime currentBar = iTime(symbol, PERIOD_CURRENT, 0);
   
   // 每10个tick更新一次标签（减少刷新频率）
   updateCounter++;
   if(updateCounter >= 10 || currentBar != lastDrawnTime) {
      DrawTrendLabel(trend, adx);
      updateCounter = 0;
   }
   
   // 如果无明确趋势，只显示标签，不显示箭头
   if(trend == TREND_NONE) {
      return;
   }
   
   // 检查是否是新K线或趋势变化
   bool shouldDraw = (currentBar != lastDrawnTime) || (trend != lastDrawnTrend);
   
   if(!shouldDraw) {
      return; // 同一根K线，趋势未变，不重复画
   }
   
   // 获取当前K线时间和价格
   double price = iClose(symbol, PERIOD_CURRENT, 0);
   
   // 根据趋势方向选择箭头和颜色
   int arrowCode;
   color arrowColor;
   string text;
   
   if(trend == TREND_UP) {
      arrowCode = 233;  // 上箭头
      arrowColor = clrLime;
      text = "UP";
   } else if(trend == TREND_DOWN) {
      arrowCode = 234;  // 下箭头
      arrowColor = clrRed;
      text = "DOWN";
   } else if(trend == TREND_WEAK) {
      arrowCode = 108;  // 圆点
      arrowColor = clrOrange;
      text = "WEAK";
   }
   
   // 创建唯一的对象名（带时间戳）
   string objName = StringFormat("PyramidTrend_Arrow_%d", currentBar);
   
   // 删除旧对象（如果存在）
   if(ObjectFind(objName) >= 0) {
      ObjectDelete(objName);
   }
   
   // 创建箭头标记
   if(ObjectCreate(objName, OBJ_ARROW, 0, currentBar, price)) {
      ObjectSet(objName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSet(objName, OBJPROP_COLOR, arrowColor);
      ObjectSet(objName, OBJPROP_WIDTH, 2);
      ObjectSet(objName, OBJPROP_BACK, false);  // 前景显示
   }
   
   // 创建文本标签
   string textName = StringFormat("PyramidTrend_Text_%d", currentBar);
   if(ObjectFind(textName) >= 0) {
      ObjectDelete(textName);
   }
   
   string fullText = StringFormat("%s(%.0f)", text, adx);
   
   // 调整文本位置（在箭头旁边）
   double textPrice = price;
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   if(trend == TREND_UP) {
      textPrice = price - atr * 0.5;
   } else {
      textPrice = price + atr * 0.5;
   }
   
   if(ObjectCreate(textName, OBJ_TEXT, 0, currentBar, textPrice)) {
      ObjectSetText(textName, fullText, 9, "Arial", arrowColor);
      ObjectSet(textName, OBJPROP_BACK, false);
   }
   
   // 记录本次绘制
   lastDrawnTrend = trend;
   lastDrawnTime = currentBar;
}

//+------------------------------------------------------------------+
//| 在图表右上角显示趋势状态                                           |
//+------------------------------------------------------------------+
void DrawTrendLabel(TrendSignal trend, double adx) {
   string labelName = "PyramidTrend_Status";
   ObjectDelete(labelName);
   
   // 创建标签
   ObjectCreate(labelName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(labelName, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet(labelName, OBJPROP_XDISTANCE, 10);
   ObjectSet(labelName, OBJPROP_YDISTANCE, 50);
   
   string text;
   color textColor;
   
   if(trend == TREND_UP) {
      text = StringFormat("▲ UPTREND | ADX: %.1f | Levels: %d/%d", 
                          adx, g_currentLevel, MaxPyramidLevels);
      textColor = clrLime;
   } else if(trend == TREND_DOWN) {
      text = StringFormat("▼ DOWNTREND | ADX: %.1f | Levels: %d/%d", 
                          adx, g_currentLevel, MaxPyramidLevels);
      textColor = clrRed;
   } else if(trend == TREND_WEAK) {
      text = StringFormat("● WEAK TREND | ADX: %.1f", adx);
      textColor = clrOrange;
   } else {
      text = StringFormat("○ NO TREND | ADX: %.1f", adx);
      textColor = clrGray;
   }
   
   ObjectSetText(labelName, text, 12, "Arial Bold", textColor);
}

//+------------------------------------------------------------------+
//| 在图表上标记订单（入场/加仓）                                        |
//+------------------------------------------------------------------+
void DrawOrderMarker(string symbol, int ticket, double price, TrendSignal trend, int level) {
   datetime orderTime = TimeCurrent();
   if(OrderSelect(ticket, SELECT_BY_TICKET)) {
      orderTime = OrderOpenTime();
   }
   
   string objName = StringFormat("Order_%d", ticket);
   
   // 删除旧对象（如果存在）
   if(ObjectFind(objName) >= 0) {
      ObjectDelete(objName);
   }
   
   // 根据方向和层级选择箭头和颜色
   int arrowCode;
   color arrowColor;
   
   if(trend == TREND_UP) {
      arrowCode = (level == 0) ? 1 : 3;  // Level 0: 大圆点, Level 1+: 小圆点
      arrowColor = clrLime;
   } else {
      arrowCode = (level == 0) ? 1 : 3;
      arrowColor = clrRed;
   }
   
   // 创建箭头标记
   if(ObjectCreate(objName, OBJ_ARROW, 0, orderTime, price)) {
      ObjectSet(objName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSet(objName, OBJPROP_COLOR, arrowColor);
      ObjectSet(objName, OBJPROP_WIDTH, level == 0 ? 4 : 2);  // Level 0更大
      ObjectSet(objName, OBJPROP_BACK, false);
   }
   
   // 添加文本标签显示Level和手数
   string textName = StringFormat("OrderText_%d", ticket);
   if(ObjectFind(textName) >= 0) {
      ObjectDelete(textName);
   }
   
   double lots = 0;
   if(OrderSelect(ticket, SELECT_BY_TICKET)) {
      lots = OrderLots();
   }
   
   string text = StringFormat("L%d: %.2f", level, lots);
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double textPrice = (trend == TREND_UP) ? price - atr * 0.3 : price + atr * 0.3;
   
   if(ObjectCreate(textName, OBJ_TEXT, 0, orderTime, textPrice)) {
      ObjectSetText(textName, text, 8, "Arial", arrowColor);
      ObjectSet(textName, OBJPROP_BACK, false);
   }
}

//+------------------------------------------------------------------+
//| 清理图表对象                                                       |
//+------------------------------------------------------------------+
void CleanupChartObjects() {
   // 清理趋势状态标签
   ObjectDelete("PyramidTrend_Status");
   
   // 清理所有趋势箭头和文本（按时间命名的对象）
   int totalObjects = ObjectsTotal();
   for(int i = totalObjects - 1; i >= 0; i--) {
      string objName = ObjectName(i);
      
      // 删除所有PyramidTrend相关对象
      if(StringFind(objName, "PyramidTrend_") >= 0 || 
         StringFind(objName, "DemoSignal_") >= 0 ||
         StringFind(objName, "Order_") >= 0 ||
         StringFind(objName, "OrderText_") >= 0) {
         ObjectDelete(objName);
      }
   }
}
//+------------------------------------------------------------------+

