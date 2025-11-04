//+------------------------------------------------------------------+
//|                                                      main.mq5    |
//|                                            EA Project Main Entry |
//+------------------------------------------------------------------+
#property copyright "EA Project"
#property link      ""
#property version   "1.00"

// Include modules
// #include "strategies/strategy.mqh"
// #include "risk/position_sizing.mqh"
// #include "exec/order_manager.mqh"
// #include "utils/logger.mqh"

// 参数从 config/params.default.json 读取，这里仅作为 MT5 界面可调整的输入
input double RiskPercentPerTrade = 0.5;    // 风险百分比 per trade (%)
input int MaxSpreadPoints = 30;             // 最大点差 (points)
input int MagicNumber = 12345;              // Magic Number

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
    Print("EA Initialized (MQL5)");
    // TODO: 加载配置文件
    // TODO: 初始化策略、风控、执行模块
    // TODO: 验证交易参数（点差、止损距离、lot step）
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("EA Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
    // TODO: 检查交易时段
    // TODO: 检查点差上限
    // TODO: 调用策略模块生成信号
    // TODO: 风险管理计算仓位
    // TODO: 执行下单逻辑
}

//+------------------------------------------------------------------+

