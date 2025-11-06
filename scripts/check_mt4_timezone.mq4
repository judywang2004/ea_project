//+------------------------------------------------------------------+
//| Check MT4 Timezone - 检查MT4时区工具                               |
//| 将此脚本拖到图表上，会在Journal显示MT4时区信息                        |
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property version   "1.00"
#property strict
#property show_inputs

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   Print("========================================");
   Print("MT4 Timezone Check | MT4时区检查");
   Print("========================================");
   
   // 获取当前服务器时间
   datetime serverTime = TimeCurrent();
   Print("Server Time: ", TimeToStr(serverTime, TIME_DATE|TIME_MINUTES));
   Print("服务器时间: ", TimeToStr(serverTime, TIME_DATE|TIME_MINUTES));
   
   // 获取本地时间
   datetime localTime = TimeLocal();
   Print("Local Time: ", TimeToStr(localTime, TIME_DATE|TIME_MINUTES));
   Print("本地时间: ", TimeToStr(localTime, TIME_DATE|TIME_MINUTES));
   
   // 计算时差
   int diffHours = int((serverTime - localTime) / 3600);
   Print("Time Difference: ", diffHours, " hours");
   Print("时差: ", diffHours, " 小时");
   
   // 估算MT4时区
   Print("");
   Print("Estimated MT4 Timezone:");
   Print("估算的MT4时区:");
   
   if(diffHours == 0) {
      Print("  → Your local time (与本地时间相同)");
   } else if(diffHours == -5 || diffHours == -4) {
      Print("  → GMT-5 / GMT-4 (New York / 纽约时间)");
      Print("  → Same as US Eastern Time! (与美东时间相同！)");
   } else if(diffHours == 2 || diffHours == 3) {
      Print("  → GMT+2 / GMT+3 (Most brokers / 大多数经纪商)");
   } else if(diffHours == 0) {
      Print("  → GMT+0 (London time / 伦敦时间)");
   } else {
      Print("  → GMT", (diffHours > 0 ? "+" : ""), diffHours);
   }
   
   Print("");
   Print("========================================");
   Print("NFP Release Time Reference:");
   Print("NFP发布时间参考:");
   Print("========================================");
   Print("US Eastern Time: 08:30");
   Print("美东时间: 08:30");
   Print("");
   
   if(diffHours == -5 || diffHours == -4) {
      Print("Your MT4 time: 08:30 (Same as US!)");
      Print("您的MT4时间: 08:30 (与美国相同！)");
   } else if(diffHours == 2) {
      Print("Your MT4 time: 15:30 (GMT+2)");
      Print("您的MT4时间: 15:30 (GMT+2)");
   } else if(diffHours == 3) {
      Print("Your MT4 time: 16:30 (GMT+3)");
      Print("您的MT4时间: 16:30 (GMT+3)");
   } else if(diffHours == 0) {
      Print("Your MT4 time: 13:30 (GMT+0)");
      Print("您的MT4时间: 13:30 (GMT+0)");
   } else {
      int nfpMT4Hour = 8 + (diffHours + 5);  // EDT is GMT-4 in summer
      Print("Your MT4 time: approximately ", nfpMT4Hour, ":30");
      Print("您的MT4时间: 大约 ", nfpMT4Hour, ":30");
   }
   
   Print("========================================");
   
   // 显示在图表上
   string display = "";
   display += "MT4 Timezone Check\n";
   display += "==================\n\n";
   display += "Server: " + TimeToStr(serverTime, TIME_DATE|TIME_MINUTES) + "\n";
   display += "Local: " + TimeToStr(localTime, TIME_DATE|TIME_MINUTES) + "\n";
   display += "Diff: " + IntegerToString(diffHours) + " hours\n\n";
   
   if(diffHours == -5 || diffHours == -4) {
      display += "Timezone: US Eastern (GMT-5/-4)\n";
      display += "NFP on MT4: 08:30 (Same!)\n";
   } else if(diffHours == 2) {
      display += "Timezone: GMT+2\n";
      display += "NFP on MT4: 15:30\n";
   } else if(diffHours == 3) {
      display += "Timezone: GMT+3\n";
      display += "NFP on MT4: 16:30\n";
   } else {
      display += "Timezone: GMT" + IntegerToString(diffHours) + "\n";
   }
   
   Comment(display);
   
   // 60秒后自动清除
   Sleep(60000);
   Comment("");
}
//+------------------------------------------------------------------+

