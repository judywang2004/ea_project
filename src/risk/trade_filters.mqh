//+------------------------------------------------------------------+
//|                                                 trade_filters.mqh |
//|                                    周末/假日/新闻/点差/波动过滤模块 |
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property strict

//+------------------------------------------------------------------+
//| 外部参数（从配置文件加载）                                          |
//+------------------------------------------------------------------+
// 周末过滤
input bool    WeekendFilterEnabled = true;        // 启用周末过滤
input int     FridayCloseHour = 21;               // 周五停止交易时刻（服务器时间）
input int     MondayOpenHour = 3;                 // 周一开始交易时刻（服务器时间）

// 假日过滤
input bool    HolidayFilterEnabled = true;        // 启用假日过滤
input string  HolidayList = "2025-01-01,2025-12-25"; // 假日列表（YYYY-MM-DD格式，逗号分隔）

// 新闻过滤
input bool    NewsFilterEnabled = true;           // 启用新闻过滤
input int     NewsAvoidMinutesBefore = 30;        // 新闻前避开分钟数
input int     NewsAvoidMinutesAfter = 30;         // 新闻后避开分钟数
input string  NewsEvents = "";                     // 重大新闻时间列表（YYYY-MM-DD HH:MM格式，分号分隔）

// 点差过滤
input bool    SpreadFilterEnabled = true;         // 启用点差过滤
input int     MaxSpreadPoints = 30;               // 最大允许点差（点数）
input double  NormalSpreadMultiplier = 2.5;       // 正常点差倍数（超过则拒绝）

// 波动过滤
input bool    VolatilityFilterEnabled = true;     // 启用波动过滤
input int     ATRPeriod = 14;                     // ATR周期
input double  MinATRValue = 0.0010;               // 最小ATR值（低于则认为波动过小）
input double  MaxATRValue = 0.0200;               // 最大ATR值（高于则认为波动过大）

//+------------------------------------------------------------------+
//| 过滤器结果结构                                                      |
//+------------------------------------------------------------------+
struct FilterResult {
   bool     passed;           // 是否通过
   string   reason;           // 拒绝原因
};

//+------------------------------------------------------------------+
//| 全局变量                                                           |
//+------------------------------------------------------------------+
datetime g_lastNewsCheckTime = 0;
double   g_normalSpread = 0;
int      g_normalSpreadSamples = 0;

//+------------------------------------------------------------------+
//| 初始化过滤器                                                        |
//+------------------------------------------------------------------+
void InitTradeFilters() {
   Print("[TradeFilters] 初始化过滤器模块");
   Print("[TradeFilters] 周末过滤: ", WeekendFilterEnabled ? "启用" : "禁用");
   Print("[TradeFilters] 假日过滤: ", HolidayFilterEnabled ? "启用" : "禁用");
   Print("[TradeFilters] 新闻过滤: ", NewsFilterEnabled ? "启用" : "禁用");
   Print("[TradeFilters] 点差过滤: ", SpreadFilterEnabled ? "启用" : "禁用");
   Print("[TradeFilters] 波动过滤: ", VolatilityFilterEnabled ? "启用" : "禁用");
   
   // 初始化正常点差基准
   if(SpreadFilterEnabled) {
      UpdateNormalSpread();
   }
}

//+------------------------------------------------------------------+
//| 主过滤函数：检查是否允许交易                                         |
//+------------------------------------------------------------------+
FilterResult CanTrade(string symbol) {
   FilterResult result;
   result.passed = true;
   result.reason = "";
   
   // 1. 周末过滤
   if(WeekendFilterEnabled) {
      result = CheckWeekendFilter();
      if(!result.passed) return result;
   }
   
   // 2. 假日过滤
   if(HolidayFilterEnabled) {
      result = CheckHolidayFilter();
      if(!result.passed) return result;
   }
   
   // 3. 新闻过滤
   if(NewsFilterEnabled) {
      result = CheckNewsFilter();
      if(!result.passed) return result;
   }
   
   // 4. 点差过滤
   if(SpreadFilterEnabled) {
      result = CheckSpreadFilter(symbol);
      if(!result.passed) return result;
   }
   
   // 5. 波动过滤
   if(VolatilityFilterEnabled) {
      result = CheckVolatilityFilter(symbol);
      if(!result.passed) return result;
   }
   
   result.passed = true;
   result.reason = "所有过滤器通过";
   return result;
}

//+------------------------------------------------------------------+
//| 周末过滤检查                                                        |
//+------------------------------------------------------------------+
FilterResult CheckWeekendFilter() {
   FilterResult result;
   result.passed = true;
   result.reason = "";
   
   datetime currentTime = TimeCurrent();
   int dayOfWeek = TimeDayOfWeek(currentTime);
   int currentHour = TimeHour(currentTime);
   
   // 周五晚上停止交易
   if(dayOfWeek == 5 && currentHour >= FridayCloseHour) {
      result.passed = false;
      result.reason = StringFormat("周五 %d:00 之后禁止交易", FridayCloseHour);
      return result;
   }
   
   // 周六全天禁止
   if(dayOfWeek == 6) {
      result.passed = false;
      result.reason = "周六禁止交易";
      return result;
   }
   
   // 周日全天禁止
   if(dayOfWeek == 0) {
      result.passed = false;
      result.reason = "周日禁止交易";
      return result;
   }
   
   // 周一早上等待市场稳定
   if(dayOfWeek == 1 && currentHour < MondayOpenHour) {
      result.passed = false;
      result.reason = StringFormat("周一 %d:00 之前禁止交易", MondayOpenHour);
      return result;
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| 假日过滤检查                                                        |
//+------------------------------------------------------------------+
FilterResult CheckHolidayFilter() {
   FilterResult result;
   result.passed = true;
   result.reason = "";
   
   if(HolidayList == "") return result;
   
   datetime currentTime = TimeCurrent();
   string currentDate = TimeToString(currentTime, TIME_DATE);
   
   // 解析假日列表
   string holidays[];
   int count = StringSplit(HolidayList, ',', holidays);
   
   for(int i = 0; i < count; i++) {
      string holiday = holidays[i];
      StringTrimLeft(holiday);
      StringTrimRight(holiday);
      
      // 转换为 MT4 格式进行比较
      string holidayMT4 = StringSubstr(holiday, 0, 4) + "." + 
                          StringSubstr(holiday, 5, 2) + "." + 
                          StringSubstr(holiday, 8, 2);
      
      if(currentDate == holidayMT4) {
         result.passed = false;
         result.reason = StringFormat("假日禁止交易: %s", holiday);
         return result;
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| 新闻过滤检查                                                        |
//+------------------------------------------------------------------+
FilterResult CheckNewsFilter() {
   FilterResult result;
   result.passed = true;
   result.reason = "";
   
   if(NewsEvents == "") return result;
   
   datetime currentTime = TimeCurrent();
   
   // 解析新闻事件列表（格式：YYYY-MM-DD HH:MM;YYYY-MM-DD HH:MM;...）
   string events[];
   int count = StringSplit(NewsEvents, ';', events);
   
   for(int i = 0; i < count; i++) {
      string event = events[i];
      StringTrimLeft(event);
      StringTrimRight(event);
      
      if(event == "") continue;
      
      // 转换时间格式：YYYY-MM-DD HH:MM → YYYY.MM.DD HH:MM (MT4格式)
      // 修复：StringToTime只能解析点分隔格式
      string eventMT4 = "";
      if(StringLen(event) >= 16) {  // 至少 "YYYY-MM-DD HH:MM"
         eventMT4 = StringSubstr(event, 0, 4) + "." +    // YYYY
                    StringSubstr(event, 5, 2) + "." +    // MM
                    StringSubstr(event, 8, 2) + " " +    // DD
                    StringSubstr(event, 11, 5);          // HH:MM
      }
      
      datetime newsTime = StringToTime(eventMT4);
      
      if(newsTime == 0) {
         Print("[警告] 无法解析新闻时间: ", event, " (转换后: ", eventMT4, ")");
         continue;
      }
      
      int minutesDiff = (int)((currentTime - newsTime) / 60);
      
      // 检查是否在避开时间窗口内
      if(minutesDiff >= -NewsAvoidMinutesBefore && minutesDiff <= NewsAvoidMinutesAfter) {
         result.passed = false;
         result.reason = StringFormat("新闻事件避开时段: %s (前%d分钟/后%d分钟)", 
                                     event, NewsAvoidMinutesBefore, NewsAvoidMinutesAfter);
         return result;
      }
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| 点差过滤检查                                                        |
//+------------------------------------------------------------------+
FilterResult CheckSpreadFilter(string symbol) {
   FilterResult result;
   result.passed = true;
   result.reason = "";
   
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   if(point == 0) {
      result.passed = false;
      result.reason = "无法获取品种Point值";
      return result;
   }
   
   double spreadPoints = (ask - bid) / point;
   
   // 检查1：绝对点差上限
   if(spreadPoints > MaxSpreadPoints) {
      result.passed = false;
      result.reason = StringFormat("点差过大: %.1f 点 (上限: %d 点)", 
                                   spreadPoints, MaxSpreadPoints);
      return result;
   }
   
   // 检查2：相对正常点差倍数
   if(g_normalSpread > 0 && spreadPoints > g_normalSpread * NormalSpreadMultiplier) {
      result.passed = false;
      result.reason = StringFormat("点差异常: %.1f 点 (正常: %.1f 点, 倍数: %.1f)", 
                                   spreadPoints, g_normalSpread, NormalSpreadMultiplier);
      return result;
   }
   
   // 更新正常点差统计
   UpdateNormalSpread();
   
   return result;
}

//+------------------------------------------------------------------+
//| 波动过滤检查（基于ATR）                                             |
//+------------------------------------------------------------------+
FilterResult CheckVolatilityFilter(string symbol) {
   FilterResult result;
   result.passed = true;
   result.reason = "";
   
   // 计算ATR
   double atr = iATR(symbol, PERIOD_CURRENT, ATRPeriod, 0);
   
   if(atr <= 0) {
      result.passed = false;
      result.reason = "无法计算ATR值";
      return result;
   }
   
   // 检查波动是否过小
   if(atr < MinATRValue) {
      result.passed = false;
      result.reason = StringFormat("波动过小: ATR=%.5f (最小: %.5f)", 
                                   atr, MinATRValue);
      return result;
   }
   
   // 检查波动是否过大
   if(atr > MaxATRValue) {
      result.passed = false;
      result.reason = StringFormat("波动过大: ATR=%.5f (最大: %.5f)", 
                                   atr, MaxATRValue);
      return result;
   }
   
   return result;
}

//+------------------------------------------------------------------+
//| 更新正常点差基准值（使用移动平均）                                   |
//+------------------------------------------------------------------+
void UpdateNormalSpread() {
   string symbol = Symbol();
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   
   if(point == 0) return;
   
   double currentSpread = (ask - bid) / point;
   
   // 过滤异常点差
   if(currentSpread > MaxSpreadPoints) return;
   
   // 使用简单移动平均更新正常点差
   if(g_normalSpreadSamples < 100) {
      g_normalSpread = (g_normalSpread * g_normalSpreadSamples + currentSpread) / (g_normalSpreadSamples + 1);
      g_normalSpreadSamples++;
   } else {
      // 指数移动平均
      g_normalSpread = g_normalSpread * 0.95 + currentSpread * 0.05;
   }
}

//+------------------------------------------------------------------+
//| 获取当前过滤器状态（用于日志和监控）                                 |
//+------------------------------------------------------------------+
string GetFilterStatus(string symbol) {
   string status = "";
   
   // 周末状态
   int dayOfWeek = TimeDayOfWeek(TimeCurrent());
   status += StringFormat("周几: %d | ", dayOfWeek);
   
   // 点差状态
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point > 0) {
      double spread = (ask - bid) / point;
      status += StringFormat("点差: %.1f (正常: %.1f) | ", spread, g_normalSpread);
   }
   
   // ATR状态
   double atr = iATR(symbol, PERIOD_CURRENT, ATRPeriod, 0);
   status += StringFormat("ATR: %.5f", atr);
   
   return status;
}

//+------------------------------------------------------------------+
//| 记录过滤器拒绝日志                                                  |
//+------------------------------------------------------------------+
void LogFilterRejection(string filter_name, string reason) {
   Print("[TradeFilters] ", filter_name, " 拒绝: ", reason);
}

//+------------------------------------------------------------------+

