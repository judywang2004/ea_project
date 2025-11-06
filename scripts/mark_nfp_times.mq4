//+------------------------------------------------------------------+
//| Mark NFP Times - 在图表上标记NFP时间                               |
//| 自动在历史NFP发布时间绘制垂直线                                      |
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property version   "1.00"
#property strict
#property show_inputs

// 输入参数
input color NFP_LineColor = clrYellow;       // NFP线条颜色
input int   NFP_LineWidth = 2;               // 线条宽度
input ENUM_LINE_STYLE NFP_LineStyle = STYLE_SOLID;  // 线条样式
input bool  ShowLabel = true;                // 显示标签

//+------------------------------------------------------------------+
//| 2024年NFP日期（美东时间08:30）                                     |
//+------------------------------------------------------------------+
datetime NFP_Times[] = {
   D'2024.01.05 08:30',
   D'2024.02.02 08:30',
   D'2024.03.08 08:30',
   D'2024.04.05 08:30',
   D'2024.05.03 08:30',
   D'2024.06.07 08:30',
   D'2024.07.05 08:30',
   D'2024.08.02 08:30',  // ← 这是您看到的那次！
   D'2024.09.06 08:30',
   D'2024.10.04 08:30',
   D'2024.11.01 08:30',
   D'2024.12.06 08:30'
};

// GMT+2时区的NFP时间（如果您的MT4是GMT+2）
datetime NFP_Times_GMT2[] = {
   D'2024.01.05 15:30',
   D'2024.02.02 15:30',
   D'2024.03.08 15:30',
   D'2024.04.05 15:30',
   D'2024.05.03 15:30',
   D'2024.06.07 15:30',
   D'2024.07.05 15:30',
   D'2024.08.02 15:30',
   D'2024.09.06 15:30',
   D'2024.10.04 15:30',
   D'2024.11.01 15:30',
   D'2024.12.06 15:30'
};

// GMT+3时区的NFP时间
datetime NFP_Times_GMT3[] = {
   D'2024.01.05 16:30',
   D'2024.02.02 16:30',
   D'2024.03.08 16:30',
   D'2024.04.05 16:30',
   D'2024.05.03 16:30',
   D'2024.06.07 16:30',
   D'2024.07.05 16:30',
   D'2024.08.02 16:30',
   D'2024.09.06 16:30',
   D'2024.10.04 16:30',
   D'2024.11.01 16:30',
   D'2024.12.06 16:30'
};

// 根据您看到的"11:00开始波动"，可能是GMT-1或GMT-2
datetime NFP_Times_Custom[] = {
   D'2024.01.05 11:30',
   D'2024.02.02 11:30',
   D'2024.03.08 11:30',
   D'2024.04.05 11:30',
   D'2024.05.03 11:30',
   D'2024.06.07 11:30',
   D'2024.07.05 11:30',
   D'2024.08.02 11:30',
   D'2024.09.06 11:30',
   D'2024.10.04 11:30',
   D'2024.11.01 11:30',
   D'2024.12.06 11:30'
};

input int TimezoneChoice = 0;  // 0=Auto Detect, 1=US Eastern, 2=GMT+2, 3=GMT+3, 4=Custom(11:30)

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   Print("========================================");
   Print("Marking NFP Times on Chart");
   Print("在图表上标记NFP时间");
   Print("========================================");
   
   // 选择时区
   datetime times[];
   ArrayResize(times, 0);
   
   if(TimezoneChoice == 1) {
      ArrayCopy(times, NFP_Times);
      Print("Using US Eastern Time (GMT-5/-4)");
   } else if(TimezoneChoice == 2) {
      ArrayCopy(times, NFP_Times_GMT2);
      Print("Using GMT+2");
   } else if(TimezoneChoice == 3) {
      ArrayCopy(times, NFP_Times_GMT3);
      Print("Using GMT+3");
   } else if(TimezoneChoice == 4) {
      ArrayCopy(times, NFP_Times_Custom);
      Print("Using Custom Time (11:30)");
   } else {
      // 自动检测
      datetime serverTime = TimeCurrent();
      datetime localTime = TimeLocal();
      int diffHours = int((serverTime - localTime) / 3600);
      
      if(diffHours >= 1 && diffHours <= 4) {
         ArrayCopy(times, NFP_Times_GMT2);
         Print("Auto-detected: GMT+2/+3");
      } else if(diffHours >= -6 && diffHours <= -3) {
         ArrayCopy(times, NFP_Times);
         Print("Auto-detected: US Eastern");
      } else {
         ArrayCopy(times, NFP_Times_Custom);
         Print("Auto-detected: Custom (11:30)");
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

