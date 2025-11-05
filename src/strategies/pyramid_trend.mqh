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
input double  ADX_Threshold = 25.0;           // ADX Threshold

// === Pyramid Addition Parameters ===
input int     MaxPyramidLevels = 4;           // Max Pyramid Levels
input double  PyramidRatio = 0.618;           // Pyramid Ratio (Fibonacci)
input double  MinProfitPointsToAdd = 50;     // Min Profit Points to Add
input double  PriceDistanceMultiplier = 1.5; // Price Distance Multiplier (x ATR)

// === Risk Management Parameters ===
input double  InitialRiskPercent = 0.5;       // Initial Risk Percent (default 0.5% per .cursorrules)
input double  MaxTotalRiskPercent = 2.0;      // Max Total Risk Percent (default <=2% per .cursorrules)
input double  TrailStopATRMultiplier = 2.5;   // Trail Stop ATR Multiplier
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
   
   // 上升趋势：快线>慢线 + 价格>长期均线 + ADX强 + +DI>-DI
   if(ema_fast > ema_slow && price > ema_filter && strongTrend && plus_di > minus_di) {
      if(g_currentTrend != TREND_UP) {
         Print("[Strategy] Uptrend detected - EMA(", TrendMA_Fast, "):", ema_fast,  // 识别到上升趋势
               " > EMA(", TrendMA_Slow, "):", ema_slow, " | ADX:", adx);
      }
      return TREND_UP;
   }
   
   // 下降趋势：快线<慢线 + 价格<长期均线 + ADX强 + -DI>+DI
   if(ema_fast < ema_slow && price < ema_filter && strongTrend && minus_di > plus_di) {
      if(g_currentTrend != TREND_DOWN) {
         Print("[Strategy] Downtrend detected - EMA(", TrendMA_Fast, "):", ema_fast,  // 识别到下降趋势
               " < EMA(", TrendMA_Slow, "):", ema_slow, " | ADX:", adx);
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
//| 检查初始入场信号                                                   |
//+------------------------------------------------------------------+
void CheckEntrySignal(string symbol, TrendSignal trend) {
   if(trend == TREND_NONE || trend == TREND_WEAK) return;
   
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
   
   // 2. 计算初始止损距离
   double stopLossDistance = atr * TrailStopATRMultiplier;
   
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
   
   // 2. 检查第一单是否盈利
   if(ArraySize(g_positions) == 0) return;
   
   PyramidPosition firstPos = g_positions[0];
   if(!OrderSelect(firstPos.ticket, SELECT_BY_TICKET)) return;
   
   double currentProfit = OrderProfit();
   double profitPoints = MathAbs(OrderClosePrice() - OrderOpenPrice()) / SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(currentProfit <= 0 || profitPoints < MinProfitPointsToAdd) {
      return; // 第一单未达到盈利要求
   }
   
   // 3. 检查价格是否移动足够距离
   double currentPrice = (trend == TREND_UP) ? SymbolInfoDouble(symbol, SYMBOL_ASK) : 
                                                SymbolInfoDouble(symbol, SYMBOL_BID);
   double priceMove = MathAbs(currentPrice - g_lastAddPrice);
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double requiredMove = atr * PriceDistanceMultiplier;
   
   if(priceMove < requiredMove) {
      return; // 价格移动不足
   }
   
   // 4. 检查总风险是否超限
   double totalRisk = CalculateTotalRisk(symbol);
   if(totalRisk >= MaxTotalRiskPercent) {
      Print("[Risk Control] Total risk limit reached:", totalRisk, "% >= ", MaxTotalRiskPercent, "%");  // 总风险已达上限
      return;
   }
   
   // 5. 触发加仓
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
   
   // 2. 计算止损（与初始仓位相同逻辑）
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double stopLossDistance = atr * TrailStopATRMultiplier;
   
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
            if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrBlue)) {
               Print("[SL Update] Ticket:", OrderTicket(), " | New SL:", newSL, " | Trail:", trailDistance);
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
            if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed)) {
               Print("[SL Update] Ticket:", OrderTicket(), " | New SL:", newSL);
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

