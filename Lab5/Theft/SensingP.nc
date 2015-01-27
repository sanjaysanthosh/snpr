#include <lib6lowpan/ip.h>
#include <Timer.h>
#include "sensing.h"
#include "blip_printf.h"

module SensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface UDP as LightSend;
		interface UDP as Settings;

		interface ShellCommand as GetCmd;
		interface ShellCommand as SetCmd;

		

		interface Mount as ConfigMount;
		interface ConfigStorage;

		interface Timer<TMilli> as SensorReadTimer;
		interface ReadStream<uint16_t> as StreamPar;

		interface Timer<TMilli> as BlinkTimer;

	}
} implementation {

		enum {
			SAMPLE_SIZE = 10,
			SAMPLE_THRESHOLD = 10,
			SAMPLE_TIME= 260,
			SAMPLE_PERIOD = 10000,
		};
		//theft_report
		settings_t settings;
		nx_struct theft_report theftnode;
		

		nx_struct settings_report stats;
		struct sockaddr_in6 route_dest;
		struct sockaddr_in6 multicast;
		uint16_t m_parSamples[SAMPLE_SIZE];
		uint8_t newnumer;
		bool toggle = FALSE;

		event void Boot.booted() {

			/*default settings*/
			settings.threshold = SAMPLE_THRESHOLD;
			settings.sample_time = SAMPLE_TIME;
			settings.sample_period = SAMPLE_PERIOD; //every 10 seconds



			route_dest.sin6_port = htons(7000);
			inet_pton6(MULTICAST, &route_dest.sin6_addr);
			call LightSend.bind(7000);

			multicast.sin6_port = htons(4000);
			inet_pton6(MULTICAST, &multicast.sin6_addr);
			call Settings.bind(4000);

			call ConfigMount.mount();
		}

		event void RadioControl.startDone(error_t e) {

			/******Some conflict here happened ******/
			settings.threshold = SAMPLE_THRESHOLD;
			settings.sample_time = SAMPLE_TIME;
			settings.sample_period = SAMPLE_PERIOD; //every 10 seconds
			//printf("settings.sample_period : %d\n",settings.sample_period);
			call SensorReadTimer.startPeriodic(settings.sample_period);
		}
		event void RadioControl.stopDone(error_t e) {}

		event void ConfigMount.mountDone(error_t e) {
		if (e != SUCCESS) {
			call Leds.led0On();
			call RadioControl.start();
		} else {
				if (call ConfigStorage.valid()) {
					call ConfigStorage.read(0, &settings, sizeof(settings));
				} else {
					settings.threshold = SAMPLE_THRESHOLD;
					settings.sample_time =SAMPLE_TIME;
					settings.sample_period = SAMPLE_PERIOD;

					call RadioControl.start();
				}
			}
		}

		event void ConfigStorage.readDone(storage_addr_t addr, void* buf, storage_len_t len, error_t e) {
			call RadioControl.start();
		}

		event void ConfigStorage.writeDone(storage_addr_t addr, void* buf, storage_len_t len, error_t e) {
			call ConfigStorage.commit();
		}

		event void ConfigStorage.commitDone(error_t error) {}

		//udp interfaces
		event void LightSend.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {
			//TODO: Start LED with node iD 
			memcpy(&theftnode, data, sizeof(theftnode));
			/*being node 2 just set led light ,  and blink if id is over 7 blinking */
			if(theftnode.who <=7 ){
				call Leds.set(theftnode.who);
			}
			else{
				newnumer= theftnode.who % 7;
				call BlinkTimer.startPeriodic( 1000 );
			}
		}


		event void BlinkTimer.fired(){
			if(!toggle){
				call Leds.set(newnumer);
				toggle=TRUE;
			}else
			{
				call Leds.set(0);
				toggle=FALSE;
			}
		}

		/*******Read and Check local sensor******/

		task void report_sensor() {
			theftnode.who = TOS_NODE_ID;
			call Leds.set(0);
			/*send the theft node id */
			call LightSend.sendto(&route_dest, &theftnode, sizeof(theftnode));
		}

		task void checkStreamPar() {
			uint8_t i;
			
			uint32_t avg = 0;
			uint32_t total=0;

			
			for (i = 0; i < SAMPLE_SIZE; i++) {
				total=total+m_parSamples[i];
			}
			avg= total/SAMPLE_SIZE;
			
			if (avg < settings.threshold){
				call Leds.led0On();
				post report_sensor();
			}	
			else{
				call Leds.led0Off();
				
			}
			printf("Data Sent\n");		
			
		}

		


		event void SensorReadTimer.fired() {
			//call Leds.led2On();
			call StreamPar.postBuffer(m_parSamples, SAMPLE_SIZE);
			call StreamPar.read(settings.sample_period);
			printf("Timer Fired\n");
		}

		event void StreamPar.readDone(error_t ok, uint32_t usActualPeriod) {
		if (ok == SUCCESS) {
				post checkStreamPar();
			}
		}
		event void StreamPar.bufferDone(error_t ok, uint16_t *buf,uint16_t count) {}


		/*******************************/


		/*******Receive Setting from broadcast*******/

		task void saveConfiguration(){
			call ConfigStorage.write(0, &settings, sizeof(settings));
		}

		task void saveConfigurationAndSend(){
			call ConfigStorage.write(0, &settings, sizeof(settings));
			
		}

		event void Settings.recvfrom(struct sockaddr_in6 *from, void *data, uint16_t len, struct ip6_metadata *meta) {
			memcpy(&stats, data, sizeof(stats));
			/**check for SETTINGS_USER*/
			if(stats.type == SETTINGS_USER){
				settings.threshold = stats.settings.threshold;
				settings.sample_time = stats.settings.sample_time;
				settings.sample_period = stats.settings.sample_period;
				post saveConfiguration();
			}
		}



		/********************************************/
		//udp shell

		event char *GetCmd.eval(int argc, char **argv) {
			char *ret = call GetCmd.getBuffer(40);
			if (ret != NULL) {
				switch (argc) {
					case 1:
						sprintf(ret, "\t[Period: %u]\n\t[Threshold: %u]\n", settings.sample_period, settings.threshold);
						break;
					case 2: 
						if (!strcmp("per",argv[1])) {
							sprintf(ret, "\t[Period: %u]\n", settings.sample_period);
						} else if (!strcmp("th", argv[1])) {
							sprintf(ret, "\t[Threshold: %u]\n",settings.threshold);
						} else {
							strcpy(ret, "Usage: get [per|th]\n");
						}
						break;
					default:
						strcpy(ret, "Usage: get [per|th]\n");
				}
			}
			return ret;
		}


		event char *SetCmd.eval(int argc, char **argv) {
			char *ret = call SetCmd.getBuffer(40);
			if (ret != NULL) {
				if (argc == 3) { 
					if (!strcmp("per",argv[1])) {
						settings.sample_period = atoi(argv[2]);
						sprintf(ret, ">>>Period changed to %u\n",settings.sample_period);
						/*Save locally*/
						post saveConfigurationAndSend();
					} else if (!strcmp("th", argv[1])) {
						settings.threshold = atoi(argv[2]);
						sprintf(ret, ">>>Threshold changed to %u\n",settings.threshold);
						/*Save locally*/
						post saveConfigurationAndSend();
					} else {
						strcpy(ret,"Usage: set per|th [<sampleperiod in ms>|<threshold>]\n");
					}
				} else {
					strcpy(ret,"Usage: set per|th [<sampleperiod in ms>|<threshold>]\n");
				}
			}
			return ret;
		}


}

