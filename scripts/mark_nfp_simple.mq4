//+------------------------------------------------------------------+
//| Mark NFP Times - Simple Version with Custom Hour Input
//| 简化版NFP标记工具 - 可自定义小时输入
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property version   "4.00"
#property strict
#property show_inputs

// Input Parameters (输入参数)
input int    NFP_Hour = 11;                      // NFP Hour on YOUR MT4 (您MT4上的NFP小时)
input int    NFP_Minute = 30;                    // NFP Minute (分钟，通常30)
input color  NFP_LineColor = clrYellow;          // NFP Line Color
input int    NFP_LineWidth = 2;                  // Line Width
input ENUM_LINE_STYLE NFP_LineStyle = STYLE_SOLID; // Line Style
input bool   ShowLabel = true;                   // Show Label

//+------------------------------------------------------------------+
//| 2024-2025 NFP Dates (All timezones, just change the hour)
//| 2024-2025年NFP日期（所有时区通用，只需改小时）
//+------------------------------------------------------------------+
string NFP_Dates[] = {
   // 2024
   "2024.01.05", "2024.02.02", "2024.03.08", "2024.04.05",
   "2024.05.03", "2024.06.07", "2024.07.05", "2024.08.02",
   "2024.09.06", "2024.10.04", "2024.11.01", "2024.12.06",
   // 2025
   "2025.01.10", "2025.02.07", "2025.03.07", "2025.04.04",
   "2025.05.02", "2025.06.06", "2025.07.03", "2025.08.01",
   "2025.09.05", "2025.10.03", "2025.11.07", "2025.12.05"
};

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   Print("========================================");
   Print("Marking NFP Times on Chart - Simple Version");
   Print("在图表上标记NFP时间 - 简化版");
   Print("========================================");
   Print("NFP Time on your MT4: ", NFP_Hour, ":", (NFP_Minute < 10 ? "0" : ""), NFP_Minute);
   Print("您MT4上的NFP时间: ", NFP_Hour, ":", (NFP_Minute < 10 ? "0" : ""), NFP_Minute);
   
   // 删除旧的NFP线条 (Delete old NFP lines)
   for(int i = ObjectsTotal() - 1; i >= 0; i--) {
      string objName = ObjectName(i);
      if(StringFind(objName, "NFP_") >= 0) {
         ObjectDelete(objName);
      }
   }
   Print("Old NFP lines deleted | 已删除旧的NFP线条");
   
   // 绘制NFP垂直线 (Draw NFP vertical lines)
   int markedCount = 0;
   
   for(int i = 0; i < ArraySize(NFP_Dates); i++) {
      // 构建完整的时间字符串 (Build full datetime string)
      string dateStr = NFP_Dates[i];
      
      // 将 YYYY.MM.DD 转换为 YYYY-MM-DD (StrToTime需要破折号格式)
      // Convert YYYY.MM.DD to YYYY-MM-DD format for StrToTime
      StringReplace(dateStr, ".", "-");
      
      string timeStr = StringFormat("%02d:%02d", NFP_Hour, NFP_Minute);
      string fullTimeStr = dateStr + " " + timeStr;
      
      datetime nfpTime = StrToTime(fullTimeStr);
      
      if(nfpTime == 0) {
         Print("Failed to parse: ", fullTimeStr);
         continue;
      }
      
      Print("Parsing: ", fullTimeStr, " → ", TimeToStr(nfpTime, TIME_DATE|TIME_MINUTES));
      
      // 检查这个时间是否在图表范围内 (Check if within chart range)
      if(nfpTime < Time[Bars - 1] || nfpTime > Time[0]) {
         continue;  // Outside chart range
      }
      
      // 创建垂直线 (Create vertical line)
      string lineName = "NFP_" + dateStr;
      
      if(ObjectCreate(lineName, OBJ_VLINE, 0, nfpTime, 0)) {
         ObjectSet(lineName, OBJPROP_COLOR, NFP_LineColor);
         ObjectSet(lineName, OBJPROP_STYLE, NFP_LineStyle);
         ObjectSet(lineName, OBJPROP_WIDTH, NFP_LineWidth);
         ObjectSet(lineName, OBJPROP_BACK, true);  // 背景显示
         
         if(ShowLabel) {
            ObjectSetText(lineName, "NFP " + dateStr + " " + timeStr);
         }
         
         markedCount++;
         Print("✓ Marked: ", dateStr, " at ", timeStr);
      }
   }
   
   Print("========================================");
   Print("Total NFP lines marked: ", markedCount);
   Print("已标记NFP线条数量: ", markedCount);
   Print("========================================");
   
   if(markedCount == 0) {
      Alert("No NFP times found in current chart range!\n"
            "当前图表范围内没有找到NFP时间！\n"
            "Try zooming out or check your date range.");
   } else {
      string msg = StringFormat(
         "✓ Marked %d NFP times at %02d:%02d on your MT4!\n"
         "✓ 已在图表上标记 %d 个NFP时间（%02d:%02d）！\n\n"
         "If lines don't align with volatility:\n"
         "如果黄线不对准波动：\n"
         "1. Check the big green candle's hour\n"
         "   查看大绿K线的小时数\n"
         "2. Re-run script with that hour\n"
         "   用那个小时数重新运行脚本",
         markedCount, NFP_Hour, NFP_Minute, markedCount, NFP_Hour, NFP_Minute
      );
      Alert(msg);
   }
}
//+------------------------------------------------------------------+

