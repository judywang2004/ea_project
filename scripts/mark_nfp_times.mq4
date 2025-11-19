//+------------------------------------------------------------------+
//| Mark NFP Times - Mark NFP release times on chart
//| Automatically draws vertical lines at historical NFP times
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property version   "2.00"
#property strict
#property show_inputs

// Input Parameters (输入参数)
input color NFP_LineColor = clrYellow;       // NFP Line Color
input int   NFP_LineWidth = 2;               // Line Width
input ENUM_LINE_STYLE NFP_LineStyle = STYLE_SOLID;  // Line Style
input bool  ShowLabel = true;                // Show Label

//+------------------------------------------------------------------+
//| NFP Dates 2024-2025 (US Eastern Time 08:30)
//| NFP日期2024-2025（美东时间08:30）
//+------------------------------------------------------------------+
// US Eastern Time (GMT-5/-4) - 美东时间
datetime NFP_Times[] = {
   // 2024
   D'2024.01.05 08:30',
   D'2024.02.02 08:30',
   D'2024.03.08 08:30',
   D'2024.04.05 08:30',
   D'2024.05.03 08:30',
   D'2024.06.07 08:30',
   D'2024.07.05 08:30',
   D'2024.08.02 08:30',
   D'2024.09.06 08:30',
   D'2024.10.04 08:30',
   D'2024.11.01 08:30',
   D'2024.12.06 08:30',
   // 2025
   D'2025.01.10 08:30',
   D'2025.02.07 08:30',
   D'2025.03.07 08:30',
   D'2025.04.04 08:30',
   D'2025.05.02 08:30',
   D'2025.06.06 08:30',
   D'2025.07.03 08:30',
   D'2025.08.01 08:30',
   D'2025.09.05 08:30',
   D'2025.10.03 08:30',
   D'2025.11.07 08:30',
   D'2025.12.05 08:30'
};

// GMT+2 Timezone - GMT+2时区
datetime NFP_Times_GMT2[] = {
   // 2024
   D'2024.01.05 15:30', D'2024.02.02 15:30', D'2024.03.08 15:30', D'2024.04.05 15:30',
   D'2024.05.03 15:30', D'2024.06.07 15:30', D'2024.07.05 15:30', D'2024.08.02 15:30',
   D'2024.09.06 15:30', D'2024.10.04 15:30', D'2024.11.01 15:30', D'2024.12.06 15:30',
   // 2025
   D'2025.01.10 15:30', D'2025.02.07 15:30', D'2025.03.07 15:30', D'2025.04.04 15:30',
   D'2025.05.02 15:30', D'2025.06.06 15:30', D'2025.07.03 15:30', D'2025.08.01 15:30',
   D'2025.09.05 15:30', D'2025.10.03 15:30', D'2025.11.07 15:30', D'2025.12.05 15:30'
};

// GMT+3 Timezone - GMT+3时区
datetime NFP_Times_GMT3[] = {
   // 2024
   D'2024.01.05 16:30', D'2024.02.02 16:30', D'2024.03.08 16:30', D'2024.04.05 16:30',
   D'2024.05.03 16:30', D'2024.06.07 16:30', D'2024.07.05 16:30', D'2024.08.02 16:30',
   D'2024.09.06 16:30', D'2024.10.04 16:30', D'2024.11.01 16:30', D'2024.12.06 16:30',
   // 2025
   D'2025.01.10 16:30', D'2025.02.07 16:30', D'2025.03.07 16:30', D'2025.04.04 16:30',
   D'2025.05.02 16:30', D'2025.06.06 16:30', D'2025.07.03 16:30', D'2025.08.01 16:30',
   D'2025.09.05 16:30', D'2025.10.03 16:30', D'2025.11.07 16:30', D'2025.12.05 16:30'
};

// GMT-6 Timezone (US Central / Mountain DST) - If you see NFP at 07:30
// GMT-6时区（美国中部/山地夏令时）- 如果您看到NFP在07:30
datetime NFP_Times_GMT_Minus6[] = {
   // 2024
   D'2024.01.05 07:30', D'2024.02.02 07:30', D'2024.03.08 07:30', D'2024.04.05 07:30',
   D'2024.05.03 07:30', D'2024.06.07 07:30', D'2024.07.05 07:30', D'2024.08.02 07:30',
   D'2024.09.06 07:30', D'2024.10.04 07:30', D'2024.11.01 07:30', D'2024.12.06 07:30',
   // 2025
   D'2025.01.10 07:30', D'2025.02.07 07:30', D'2025.03.07 07:30', D'2025.04.04 07:30',
   D'2025.05.02 07:30', D'2025.06.06 07:30', D'2025.07.03 07:30', D'2025.08.01 07:30',
   D'2025.09.05 07:30', D'2025.10.03 07:30', D'2025.11.07 07:30', D'2025.12.05 07:30'
};

// GMT-7 Timezone (US Mountain / Pacific DST) - If you see NFP at 06:30
// GMT-7时区（美国山地/太平洋夏令时）- 如果您看到NFP在06:30
datetime NFP_Times_GMT_Minus7[] = {
   // 2024
   D'2024.01.05 06:30', D'2024.02.02 06:30', D'2024.03.08 06:30', D'2024.04.05 06:30',
   D'2024.05.03 06:30', D'2024.06.07 06:30', D'2024.07.05 06:30', D'2024.08.02 06:30',
   D'2024.09.06 06:30', D'2024.10.04 06:30', D'2024.11.01 06:30', D'2024.12.06 06:30',
   // 2025
   D'2025.01.10 06:30', D'2025.02.07 06:30', D'2025.03.07 06:30', D'2025.04.04 06:30',
   D'2025.05.02 06:30', D'2025.06.06 06:30', D'2025.07.03 06:30', D'2025.08.01 06:30',
   D'2025.09.05 06:30', D'2025.10.03 06:30', D'2025.11.07 06:30', D'2025.12.05 06:30'
};

// Custom Time (if you see volatility around 11:00-12:00)
// 自定义时间（如果您看到11:00-12:00左右波动）
datetime NFP_Times_Custom[] = {
   // 2024
   D'2024.01.05 11:30', D'2024.02.02 11:30', D'2024.03.08 11:30', D'2024.04.05 11:30',
   D'2024.05.03 11:30', D'2024.06.07 11:30', D'2024.07.05 11:30', D'2024.08.02 11:30',
   D'2024.09.06 11:30', D'2024.10.04 11:30', D'2024.11.01 11:30', D'2024.12.06 11:30',
   // 2025
   D'2025.01.10 11:30', D'2025.02.07 11:30', D'2025.03.07 11:30', D'2025.04.04 11:30',
   D'2025.05.02 11:30', D'2025.06.06 11:30', D'2025.07.03 11:30', D'2025.08.01 11:30',
   D'2025.09.05 11:30', D'2025.10.03 11:30', D'2025.11.07 11:30', D'2025.12.05 11:30'
};

input int TimezoneChoice = 0;  // 0=Auto, 1=US Eastern(8:30), 2=GMT+2(15:30), 3=GMT+3(16:30), 4=GMT-6(7:30), 5=GMT-7(6:30), 6=Custom(11:30)

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   Print("========================================");
   Print("Marking NFP Times on Chart");
   Print("在图表上标记NFP时间");
   Print("========================================");
   
   // 选择时区 (Select timezone)
   datetime times[];
   ArrayResize(times, 0);
   
   if(TimezoneChoice == 1) {
      ArrayCopy(times, NFP_Times);
      Print("Using US Eastern Time (08:30 GMT-5/-4)");
   } else if(TimezoneChoice == 2) {
      ArrayCopy(times, NFP_Times_GMT2);
      Print("Using GMT+2 (15:30)");
   } else if(TimezoneChoice == 3) {
      ArrayCopy(times, NFP_Times_GMT3);
      Print("Using GMT+3 (16:30)");
   } else if(TimezoneChoice == 4) {
      ArrayCopy(times, NFP_Times_GMT_Minus6);
      Print("Using GMT-6 (07:30 US Central/Mountain DST)");
   } else if(TimezoneChoice == 5) {
      ArrayCopy(times, NFP_Times_GMT_Minus7);
      Print("Using GMT-7 (06:30 US Mountain/Pacific DST)");
   } else if(TimezoneChoice == 6) {
      ArrayCopy(times, NFP_Times_Custom);
      Print("Using Custom Time (11:30)");
   } else {
      // 自动检测 (Auto-detect)
      datetime serverTime = TimeCurrent();
      datetime localTime = TimeLocal();
      
      // 只比较小时，避免跨月问题
      int serverHour = TimeHour(serverTime);
      int localHour = TimeHour(localTime);
      int diffHours = serverHour - localHour;
      
      // 处理跨日
      if(diffHours > 12) diffHours -= 24;
      if(diffHours < -12) diffHours += 24;
      
      Print("Auto-detect: Server hour=", serverHour, ", Local hour=", localHour, ", Diff=", diffHours);
      
      if(diffHours >= 1 && diffHours <= 4) {
         ArrayCopy(times, NFP_Times_GMT2);
         Print("Auto-detected: GMT+2/+3 (15:30/16:30)");
      } else if(diffHours >= -8 && diffHours <= -6) {
         ArrayCopy(times, NFP_Times_GMT_Minus7);
         Print("Auto-detected: GMT-7/-6 (06:30/07:30)");
      } else if(diffHours >= -5 && diffHours <= -3) {
         ArrayCopy(times, NFP_Times);
         Print("Auto-detected: US Eastern (08:30)");
      } else {
         ArrayCopy(times, NFP_Times_GMT_Minus7);
         Print("Default: GMT-7 (06:30) - Please manually select timezone!");
      }
   }
   
   // 删除旧的NFP线条
   for(int i = ObjectsTotal() - 1; i >= 0; i--) {
      string objName = ObjectName(i);
      if(StringFind(objName, "NFP_") >= 0) {
         ObjectDelete(objName);
      }
   }
   
   // 绘制NFP垂直线
   int markedCount = 0;
   for(int i = 0; i < ArraySize(times); i++) {
      datetime nfpTime = times[i];
      
      // 检查这个时间是否在图表范围内
      if(nfpTime < Time[Bars - 1] || nfpTime > Time[0]) {
         continue;  // 超出图表范围
      }
      
      string lineName = StringFormat("NFP_%s", TimeToStr(nfpTime, TIME_DATE));
      
      if(ObjectCreate(lineName, OBJ_VLINE, 0, nfpTime, 0)) {
         ObjectSet(lineName, OBJPROP_COLOR, NFP_LineColor);
         ObjectSet(lineName, OBJPROP_STYLE, NFP_LineStyle);
         ObjectSet(lineName, OBJPROP_WIDTH, NFP_LineWidth);
         ObjectSet(lineName, OBJPROP_BACK, true);  // 背景显示
         
         if(ShowLabel) {
            ObjectSetText(lineName, "NFP " + TimeToStr(nfpTime, TIME_DATE));
         }
         
         markedCount++;
         Print("Marked NFP: ", TimeToStr(nfpTime, TIME_DATE|TIME_MINUTES));
      }
   }
   
   Print("========================================");
   Print("Total NFP lines marked: ", markedCount);
   Print("已标记NFP线条数量: ", markedCount);
   Print("========================================");
   
   if(markedCount == 0) {
      Alert("No NFP times found in current chart range!\n当前图表范围内没有找到NFP时间！\nTry zooming out or changing TimezoneChoice.");
   } else {
      Alert(IntegerToString(markedCount) + " NFP times marked on chart!\n已在图表上标记 " + IntegerToString(markedCount) + " 个NFP时间！");
   }
}
//+------------------------------------------------------------------+

