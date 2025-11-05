//+------------------------------------------------------------------+
//|                                       trade_filters_example.mq4 |
//|                                            过滤器使用示例          |
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property strict

#include "trade_filters.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   // 初始化过滤器
   InitTradeFilters();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Print("[Example] EA停止运行");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   // 每100个tick检查一次
   static int tickCount = 0;
   tickCount++;
   
   if(tickCount % 100 != 0) return;
   
   // 检查是否允许交易
   FilterResult result = CanTrade(Symbol());
   
   if(result.passed) {
      Print("[Example] ✓ 允许交易 - ", GetFilterStatus(Symbol()));
   } else {
      Print("[Example] ✗ 禁止交易 - ", result.reason);
      LogFilterRejection("综合过滤", result.reason);
   }
}

//+------------------------------------------------------------------+
//| 交易示例函数                                                       |
//+------------------------------------------------------------------+
bool ExecuteTrade(int orderType, double lots) {
   // 1. 首先检查所有过滤器
   FilterResult filter = CanTrade(Symbol());
   
   if(!filter.passed) {
      Print("[ExecuteTrade] 交易被过滤器拒绝: ", filter.reason);
      LogFilterRejection("交易前检查", filter.reason);
      return false;
   }
   
   // 2. 过滤器通过，执行交易逻辑
   Print("[ExecuteTrade] 过滤器通过，准备下单...");
   
   // 这里添加实际的下单代码
   // int ticket = OrderSend(...);
   
   return true;
}
//+------------------------------------------------------------------+

