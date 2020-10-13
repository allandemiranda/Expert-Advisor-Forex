//+------------------------------------------------------------------+
//|                                         Expert-Advisor-Forex.mq5 |
//|                          Copyright 2020, Allan de Miranda Silva. |
//|                                    http://allandemiranda.eti.br/ |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2020, Allan de Miranda Silva."
#property link          "http://allandemiranda.eti.br"
#property version       "1.0"

//--- Bibliotecas
#include <Lib CisNewBar.mqh>
#include <Indicators\Trend.mqh>
#include <Trade\Trade.mqh>

//--- Parâmetros de entrada
input ushort magic_number = 1;                     // Número de identificação da operação
input double take_profit = 0.00020;                // Quantidade de proficiência
input double stop_loss = 0.00100;                  // Quantidade negativa na operação
input double lote_size = 0.01;                     // Tamanho do lote que irá operar
input ENUM_TIMEFRAMES time_frame = PERIOD_CURRENT; // Período de operação
input double margem_MA = 0.00003;                  // Margem de segurança da entrada
input double spreed_max = 0.00010;                 // Spreed máximo
input int cont_bar_max = 4;                        // Máximo de barras abertas

input ushort MA_yellow_period = 90;                               // Período da Média Móvel mais alta
input ushort MA_yellow_shift = 0;                                 // Deslocamento da Média Móvel mais alta
input ENUM_MA_METHOD MA_yellow_method = MODE_EMA;                 // Método da Média Móvel mais alta
input ENUM_APPLIED_PRICE MA_yellow_applied_price = PRICE_CLOSE;   // Aplicação de preço da Média Móvel mais alta

input ushort MA_blue_period = 34;                              // Período da Média Móvel mais baixa
input ushort MA_blue_shift = 0;                                // Deslocamento da Média Móvel mais baixa
input ENUM_MA_METHOD MA_blue_method = MODE_EMA;                // Método da Média Móvel mais baixa
input ENUM_APPLIED_PRICE MA_blue_applied_price = PRICE_CLOSE;  // Aplicação de preço da Média Móvel mais baixa

//--- Variáveis globais
string currency = Symbol();         // Simbolo usado para operar
CisNewBar current_chart;            // Classe para verifica se existe uma nova barra no gráfico
CiMA yellow_line;                   // Classe com a linha Média Móvel Amarelo
CiMA blue_line;                     // Classe com a linha Média Móvel Azul
ushort last_position_tick_now = 3;  // Última posição do tick no gráfico
ushort cont_bar = 0;                // Quandidade de velas pós operação
CTrade trade_now;                   // Classe para abrir uma operação
bool tick_neutral = true;           // Verifica se ele passou pelo estado neutro

//+------------------------------------------------------------------+
//| Função para verificar posição do Tick no gráfico                 |
//| @param tick_now     Valor do tick atual                          |
//| @param line_now_Y   Valor do indicador de linha amarela          |
//| @param line_now_B   Valor do indicador de linha azul             |
//| @return 0  Tick está por fora da linha amarela                   |
//| @return 1  Tick está por fora da linha azul                      |
//| @return 2  Tick está entre as linhas                             |
//| Qualquer outro valor de retorno deve ser interpretado como erro  |
//+------------------------------------------------------------------+
ushort position_tick_on_chart(double tick_now, double line_now_Y, double line_now_B) {
//---
   if((tick_now < (line_now_Y - margem_MA)) && (line_now_Y <= line_now_B)) {
      return 0;
   }

   if((tick_now > (line_now_B + margem_MA)) && (line_now_Y <= line_now_B)) {
      return 1;
   }

   if((tick_now > (line_now_Y + margem_MA)) && (line_now_B <= line_now_Y)) {
      return 0;
   }

   if((tick_now < (line_now_B - margem_MA)) && (line_now_B <= line_now_Y)) {
      return 1;
   }

   if((tick_now > (line_now_Y - margem_MA)) && (tick_now < (line_now_B + margem_MA))) {
      return 2;
   }

   if((tick_now < (line_now_Y + margem_MA)) && (tick_now > (line_now_B - margem_MA))) {
      return 2;
   }

   return(ERR_INDICATOR_WRONG_INDEX);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//--- Gerenciador de Velas no gráfico
   current_chart.SetSymbol(Symbol());
   current_chart.SetPeriod(time_frame);

//--- Criando as linhas
   yellow_line.Create(currency,time_frame,MA_yellow_period,MA_yellow_shift,MA_yellow_method,MA_yellow_applied_price);
   yellow_line.AddToChart(0,0);
   blue_line.Create(currency,time_frame,MA_blue_period,MA_blue_shift,MA_blue_method,MA_blue_applied_price);
   blue_line.AddToChart(0,0);

//--- GSerenciador de operações
   trade_now.SetExpertMagicNumber(magic_number);

//--- Comentário inicial
   Print("Sistema Iniciado");

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   EventKillTimer();

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//--- Obter valores atulizados
   MqlTick last_tick;
   yellow_line.Refresh();
   blue_line.Refresh();
   SymbolInfoTick(Symbol(),last_tick);
   
   int tempo = PeriodSeconds(time_frame)/60;

//--- Verificar se existe uma nova vela
   if(current_chart.isNewBar()) {
      cont_bar++;
   }

//--- Obter posição do Tick no gráfico
   ushort position_tick_now = position_tick_on_chart(last_tick.bid,yellow_line.Main(0),blue_line.Main(0));
   if(last_position_tick_now == 3) {
      if(position_tick_now == 2) {
         return;
      }
      last_position_tick_now = position_tick_now;
   }
   if(position_tick_now != 2) {
      if(tick_neutral == true) {
         //--- Preços vão cair
         if(blue_line.Main(0) < yellow_line.Main(0)) {
            if(last_position_tick_now != position_tick_now) {
               if(position_tick_now == 0) {
                  Print("COMPRAR 1");
                  Alert(currency, " GREEN ", tempo, " M");
                  trade_now.PositionClose(currency);
                  double stop_loss_now = last_tick.ask - stop_loss;
                  double take_profit_now = last_tick.ask + take_profit;
                  double spreed_now = last_tick.ask - last_tick.bid;
                  if(spreed_now < spreed_max) {
                     //trade_now.Buy(lote_size,currency,last_tick.ask,stop_loss_now,take_profit_now);
                  }
               } else {
                  Print("VENDER 1");
                  Alert(currency, " RED ", tempo, " M");
                  trade_now.PositionClose(currency);
                  double stop_loss_now = last_tick.bid + stop_loss;
                  double take_profit_now = last_tick.bid - take_profit;
                  double spreed_now = last_tick.ask - last_tick.bid;
                  if(spreed_now < spreed_max) {
                     //trade_now.Sell(lote_size,currency,last_tick.bid,stop_loss_now,take_profit_now);
                  }
               }
               cont_bar = 0;
               last_position_tick_now = position_tick_now;
            }
         }

//--- Preços vão subir
         if(blue_line.Main(0) > yellow_line.Main(0)) {
            if( last_position_tick_now != position_tick_now) {
               if(position_tick_now == 0) {
                  Print("VENDER 2");
                  Alert(currency, " RED ", tempo, " M");
                  trade_now.PositionClose(currency);
                  double stop_loss_now = last_tick.bid + stop_loss;
                  double take_profit_now = last_tick.bid - take_profit;
                  double spreed_now = last_tick.ask - last_tick.bid;
                  if(spreed_now < spreed_max) {
                     //trade_now.Sell(lote_size,currency,last_tick.bid,stop_loss_now,take_profit_now);
                  }
               } else {
                  Print("COMPRAR 2");
                  Alert(currency, " GREEN ", tempo, " M");
                  trade_now.PositionClose(currency);
                  double stop_loss_now = last_tick.ask - stop_loss;
                  double take_profit_now = last_tick.ask + take_profit;
                  double spreed_now = last_tick.ask - last_tick.bid;
                  if(spreed_now < spreed_max) {
                     //trade_now.Buy(lote_size,currency,last_tick.ask,stop_loss_now,take_profit_now);
                  }
               }
               cont_bar = 0;
               last_position_tick_now = position_tick_now;
            }
         }
      }
      last_position_tick_now = position_tick_now;
      tick_neutral = false;
   } else {
      tick_neutral = true;
   }

//--- Somente opere até a terceira vela
   if(cont_bar == 4) {
      trade_now.PositionClose(currency);
   }


}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
//---

}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade() {
//---

}
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result) {
//---

}
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester() {
//---
   double ret = 0.0;
//---

//---
   return(ret);
}
//+------------------------------------------------------------------+
//| TesterInit function                                              |
//+------------------------------------------------------------------+
void OnTesterInit() {
//---

}
//+------------------------------------------------------------------+
//| TesterPass function                                              |
//+------------------------------------------------------------------+
void OnTesterPass() {
//---

}
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit() {
//---

}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
//---

}
//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol) {
//---

}
//+------------------------------------------------------------------+
