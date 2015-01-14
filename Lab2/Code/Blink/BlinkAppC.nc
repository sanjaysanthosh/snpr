/*
 *@author: sanjeet raj pandey
 * Configuration for Binary counter App
 */

configuration BlinkAppC
{
}
implementation
{
  
  components MainC, LedsC, BlinkC, BinCounterP;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
 


  BlinkC -> MainC.Boot;
  BlinkC.Counter -> BinCounterP;  
  BinCounterP.Timer0 -> Timer0;
  BinCounterP.Timer1 -> Timer1;
  BinCounterP.Timer2 -> Timer2;
  BinCounterP.Leds -> LedsC;

}