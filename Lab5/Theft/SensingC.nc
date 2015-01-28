#include "StorageVolumes.h"

configuration SensingC {

} implementation {
	components MainC, LedsC, SensingP;
	SensingP.Boot -> MainC;
	SensingP.Leds -> LedsC;

	components IPStackC;
	components IPDispatchC;
	components RPLRoutingC;
	components StaticIPAddressTosIdC;
	SensingP.RadioControl -> IPStackC;

	components UdpC;
	components new UdpSocketC() as LightSend;
	SensingP.LightSend -> LightSend;
	components new UdpSocketC() as Settings;
	SensingP.Settings -> Settings;

	components UDPShellC;
	components new ShellCommandC("get") as GetCmd;
	components new ShellCommandC("set") as SetCmd;
	SensingP.GetCmd -> GetCmd;
	SensingP.SetCmd -> SetCmd;

	
	/*****Light sensor imer and sensor*****/
	components new TimerMilliC() as SensorReadTimer;
	SensingP.SensorReadTimer -> SensorReadTimer;

	components new HamamatsuS1087ParC() as SensorPar;
	SensingP.StreamPar -> SensorPar.ReadStream;


	components new ConfigStorageC(VOLUME_CONFIG) as LightSettings;
	SensingP.ConfigMount -> LightSettings;
	SensingP.ConfigStorage -> LightSettings;

	components new TimerMilliC() as BlinkTimer;
	SensingP.BlinkTimer -> BlinkTimer;

}
