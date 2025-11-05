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
input double  InitialRiskPercent = 1.0;       // Initial Risk Percent
input double  MaxTotalRiskPercent = 3.0;      // Max Total Risk Percent
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
// Current pyramid positions array
PyramidPosition g_positions[];
// Current pyramid level count
int             g_currentLevel = 0;
// Current identified trend
TrendSignal     g_currentTrend = TREND_NONE;
// Last add position price
double          g_lastAddPrice = 0;
// Last signal time (prevent duplicates)
datetime        g_lastSignalTime = 0;

//+------------------------------------------------------------------+
//| 初始化策略                                                         |
//+------------------------------------------------------------------+
void InitPyramidStrategy() {
   Print("========================================");
   Print("趋势金字塔策略 - 机构级实现");
   Print("========================================");
   Print("趋势识别: EMA(", TrendMA_Fast, ") vs EMA(", TrendMA_Slow, ") + EMA(", TrendMA_Filter, ")");
   Print("趋势强度: ADX(", ADX_Period, ") > ", ADX_Threshold);
   Print("最大层数: ", MaxPyramidLevels);
   Print("加仓比例: ", PyramidRatio);
   Print("初始风险: ", InitialRiskPercent, "%");
   Print("最大风险: ", MaxTotalRiskPercent, "%");
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
   
   // 3. 管理现有仓位
   if(g_currentLevel > 0) {
      ManageExistingPositions(symbol, trend);
   }
   
   // 4. 检查新入场机会
   if(g_currentLevel == 0) {
      CheckEntrySignal(symbol, trend);
   }
   
   // 5. 检查加仓机会
   if(g_currentLevel > 0 && g_currentLevel < MaxPyramidLevels) {
      CheckPyramidSignal(symbol, trend);
   }
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
         Print("[策略] 识别到上升趋势 - EMA(", TrendMA_Fast, "):", ema_fast, 
               " > EMA(", TrendMA_Slow, "):", ema_slow, " | ADX:", adx);
      }
      return TREND_UP;
   }
   
   // 下降趋势：快线<慢线 + 价格<长期均线 + ADX强 + -DI>+DI
   if(ema_fast < ema_slow && price < ema_filter && strongTrend && minus_di > plus_di) {
      if(g_currentTrend != TREND_DOWN) {
         Print("[策略] 识别到下降趋势 - EMA(", TrendMA_Fast, "):", ema_fast, 
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
   Print("[信号] 初始入场信号 - 趋势方向:", trend == TREND_UP ? "做多" : "做空");
   
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
      Print("[错误] 计算手数过小:", lots);
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
      Print("[开仓成功] Level 0 - Ticket:", ticket, " | 手数:", lots, 
            " | 止损距离:", stopLossDistance, " | 风险:", InitialRiskPercent, "%");
      
      // 添加到仓位数组
      AddPositionToArray(ticket, 0, price, lots, sl, tp);
      g_currentLevel = 1;
      g_lastAddPrice = price;
   } else {
      Print("[开仓失败] 错误码:", GetLastError());
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
      Print("[风控] 总风险已达上限:", totalRisk, "% >= ", MaxTotalRiskPercent, "%");
      return;
   }
   
   // 5. 触发加仓
   Print("[信号] 金字塔加仓 Level ", g_currentLevel, " - 盈利点数:", profitPoints, 
         " | 价格移动:", priceMove, " (要求:", requiredMove, ")");
   
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
      Print("[警告] 加仓手数过小，停止加仓");
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
      Print("[加仓成功] Level ", g_currentLevel, " - Ticket:", ticket, 
            " | 手数:", newLots, " (", PyramidRatio*100, "%)");
      
      AddPositionToArray(ticket, g_currentLevel, price, newLots, sl, 0);
      g_currentLevel++;
      g_lastAddPrice = price;
      
      // 更新所有仓位的止损（移动到盈亏平衡或追踪）
      UpdateAllStopLosses(symbol);
   } else {
      Print("[加仓失败] 错误码:", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 管理现有仓位                                                       |
//+------------------------------------------------------------------+
void ManageExistingPositions(string symbol, TrendSignal trend) {
   // 1. 检查趋势反转 - 全部平仓
   if(ExitOnTrendReverse && trend != g_currentTrend && trend != TREND_NONE) {
      Print("[退出] 趋势反转 - 全部平仓");
      CloseAllPyramidPositions(symbol, "趋势反转");
      return;
   }
   
   // 2. 检查趋势减弱 - 全部平仓
   if(trend == TREND_WEAK) {
      Print("[退出] 趋势减弱 - 全部平仓");
      CloseAllPyramidPositions(symbol, "趋势减弱");
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
   double atr = iATR(symbol, PERIOD_CURRENT, 14, 0);
   double trailDistance = atr * TrailStopATRMultiplier;
   
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
            double breakEvenSL = OrderOpenPrice() + 10 * SymbolInfoDouble(symbol, SYMBOL_POINT);
            if(newSL < breakEvenSL) newSL = breakEvenSL;
         }
         
         // 只向上移动
         if(newSL > currentSL) {
            if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrBlue)) {
               Print("[止损更新] Ticket:", OrderTicket(), " | 新SL:", newSL, " | 追踪距离:", trailDistance);
            }
         }
      } else {
         // 做空：追踪止损向下移动
         newSL = currentPrice + trailDistance;
         
         if(UseBreakEvenStop && currentPrice < OrderOpenPrice() - trailDistance) {
            double breakEvenSL = OrderOpenPrice() - 10 * SymbolInfoDouble(symbol, SYMBOL_POINT);
            if(newSL > breakEvenSL) newSL = breakEvenSL;
         }
         
         // 只向下移动
         if(newSL < currentSL || currentSL == 0) {
            if(OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed)) {
               Print("[止损更新] Ticket:", OrderTicket(), " | 新SL:", newSL);
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
      
      // 计算风险回报比
      double profitPoints = MathAbs(OrderClosePrice() - OrderOpenPrice()) / SymbolInfoDouble(symbol, SYMBOL_POINT);
      double riskPoints = MathAbs(OrderOpenPrice() - g_positions[i].stopLoss) / SymbolInfoDouble(symbol, SYMBOL_POINT);
      
      if(riskPoints == 0) continue;
      
      double currentRR = profitPoints / riskPoints;
      
      // 达到目标RR，部分平仓
      if(currentRR >= PartialTP_RR) {
         double closeLots = NormalizeDouble(OrderLots() * PartialTP_Percent, 2);
         
         if(closeLots >= SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN)) {
            bool closed = OrderClose(OrderTicket(), closeLots, OrderClosePrice(), 3, clrOrange);
            
            if(closed) {
               Print("[分批止盈] Ticket:", OrderTicket(), " | 平仓:", closeLots, "手 (", 
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
      
      bool closed = OrderClose(OrderTicket(), OrderLots(), OrderClosePrice(), 5, clrYellow);
      
      if(closed) {
         Print("[平仓] Ticket:", OrderTicket(), " | Level:", g_positions[i].level, 
               " | 原因:", reason, " | 盈利:", OrderProfit());
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
   string status = StringFormat("趋势:%s | 层数:%d/%d | 仓位数:%d", 
                                g_currentTrend == TREND_UP ? "上升" : 
                                g_currentTrend == TREND_DOWN ? "下降" : "无",
                                g_currentLevel, MaxPyramidLevels,
                                ArraySize(g_positions));
   
   if(ArraySize(g_positions) > 0) {
      double totalProfit = 0;
      for(int i = 0; i < ArraySize(g_positions); i++) {
         if(OrderSelect(g_positions[i].ticket, SELECT_BY_TICKET)) {
            totalProfit += OrderProfit();
         }
      }
      status += StringFormat(" | 总盈利:$%.2f", totalProfit);
   }
   
   return status;
}
//+------------------------------------------------------------------+

