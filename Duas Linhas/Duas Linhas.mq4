//+------------------------------------------------------------------+
//|                                                  Duas Linhas.mq4 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict

extern int periodo_MA_azul = 34;                // Periodo MA Azul
extern int shift_MA_azul = 0;                   // Shift MA Azul
extern ENUM_MA_METHOD metodo_MA_azul = 0;       // Método MA Azul
extern ENUM_APPLIED_PRICE applied_MA_azul = 0;  // Constante de cálculo

extern int periodo_MA_amarelo = 90;                // Periodo MA Azul
extern int shift_MA_amarelo = 0;                   // Shift MA Azul
extern ENUM_MA_METHOD metodo_MA_amarelo = 1;       // Método MA Azul
extern ENUM_APPLIED_PRICE applied_MA_amarelo = 0;  // Constante de cálculo

input double margem_MA = 0.00002;   // Margem de segurança da entrada

ushort last_position_tick_now = 3;  // Última posição do tick no gráfico
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

   return(ERR_INVALID_PRICE);
}

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping


//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
//---
   double MA_azul=iMA(NULL,_Period,periodo_MA_azul,shift_MA_azul,metodo_MA_azul,applied_MA_azul,0);
   double MA_amarelo=iMA(NULL,_Period,periodo_MA_amarelo,shift_MA_amarelo,metodo_MA_amarelo,applied_MA_amarelo,0);

   ushort position_tick_now = position_tick_on_chart(Close[0],MA_amarelo,MA_azul);

   if(last_position_tick_now == 3) {
      if(position_tick_now == 2) {
         return(NULL);
      }
      last_position_tick_now = position_tick_now;
   }

   if(position_tick_now != 2) {
      if(tick_neutral == true) {
         //--- Preços vão cair
         if(MA_azul < MA_amarelo) {
            if(last_position_tick_now != position_tick_now) {
               if(position_tick_now == 0) {
                  Print("COMPRAR 1");
                  Alert(_Symbol, " GREEN ", _Period, " M");
               } else {
                  Print("VENDER 1");
                  Alert(_Symbol, " RED ", _Period, " M");
               }
               last_position_tick_now = position_tick_now;
            }
         }

//--- Preços vão subir
         if(MA_azul >  MA_amarelo) {
            if( last_position_tick_now != position_tick_now) {
               if(position_tick_now == 0) {
                  Print("VENDER 2");
                  Alert(_Symbol, " RED ", _Period, " M");
               } else {
                  Print("COMPRAR 2");
                  Alert(_Symbol, " GREEN ", _Period, " M");
               }
               last_position_tick_now = position_tick_now;
            }
         }
      }
      last_position_tick_now = position_tick_now;
      tick_neutral = false;
   } else {
      tick_neutral = true;
   }


//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
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
