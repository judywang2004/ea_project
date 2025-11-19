//+------------------------------------------------------------------+
//| Test Mark Line - Mark a line at current visible chart time
//| 测试标记 - 在当前可见图表时间标记一条线
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   // 获取当前图表最右侧的时间 (Get rightmost visible time)
   datetime currentTime = Time[0];
   
   // 在当前时间标记一条测试线 (Mark a test line at current time)
   string lineName = "TEST_LINE";
   
   // 删除旧的测试线 (Delete old test line)
   ObjectDelete(lineName);
   
   // 创建新的测试线 (Create new test line)
   if(ObjectCreate(lineName, OBJ_VLINE, 0, currentTime, 0)) {
      ObjectSet(lineName, OBJPROP_COLOR, clrRed);
      ObjectSet(lineName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet(lineName, OBJPROP_WIDTH, 3);
      ObjectSet(lineName, OBJPROP_BACK, false);
      ObjectSetText(lineName, "TEST LINE");
      
      Print("✓ Test line marked at: ", TimeToStr(currentTime, TIME_DATE|TIME_MINUTES));
      Alert("✓ Red test line marked at current time!\n"
            "✓ 已在当前时间标记红色测试线！\n\n"
            "If you can see this red line, the script works!\n"
            "如果您能看到这条红线，说明脚本正常工作！\n\n"
            "Now navigate to 2024.08.02 to find yellow NFP lines.\n"
            "现在导航到2024.08.02找NFP黄线。");
   } else {
      Print("Failed to create test line");
   }
   
   // 显示当前图表信息 (Show current chart info)
   Print("========================================");
   Print("Current Chart Info | 当前图表信息");
   Print("========================================");
   Print("Symbol: ", Symbol());
   Print("Period: ", Period(), " (1=M1, 60=H1, 1440=D1)");
   Print("Current Time: ", TimeToStr(currentTime, TIME_DATE|TIME_MINUTES));
   Print("Earliest Bar: ", TimeToStr(Time[Bars-1], TIME_DATE|TIME_MINUTES));
   Print("Latest Bar: ", TimeToStr(Time[0], TIME_DATE|TIME_MINUTES));
   Print("Total Bars: ", Bars);
   Print("========================================");
}
//+------------------------------------------------------------------+

