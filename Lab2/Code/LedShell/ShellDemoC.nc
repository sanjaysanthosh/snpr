/*
 *@author: sanjeet raj apndey
 * ShellDemoC extended to set leds as binary representation of given number via radio
 */

configuration ShellDemoC {
}
implementation {

	components MainC, ShellDemoP, LedsC;
	ShellDemoP.Boot -> MainC.Boot;

  ShellDemoP.Led-> LedsC;
	components IPStackC;
	components UDPShellC;
	components RPLRoutingC;
	components StaticIPAddressTosIdC;

	ShellDemoP.RadioControl -> IPStackC;

	components new ShellCommandC("demo") as DemoCmd;
	ShellDemoP.DemoCmd -> DemoCmd;

  /*We add new cshellcomand for functionality to set leds as given argument from 0-7*/
  components new ShellCommandC("set") as SetCmd;
  ShellDemoP.SetCmd -> SetCmd;

#ifdef PRINTFUART_ENABLED
  /* This component wires printf directly to the serial port, and does
   * not use any framing.  You can view the output simply by tailing
   * the serial device.  Unlike the old printfUART, this allows us to
   * use PlatformSerialC to provide the serial driver.
   *
   * For instance:
   * $ stty -F /dev/ttyUSB0 115200
   * $ tail -f /dev/ttyUSB0
  */
  components SerialPrintfC;

  /* This is the alternative printf implementation which puts the
   * output in framed tinyos serial messages.  This lets you operate
   * alongside other users of the tinyos serial stack.
   */
  // components PrintfC;
  // components SerialStartC;
#endif
}
