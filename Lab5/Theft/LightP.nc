/*
 *@author: sanjeet raj pandey
 *group 2
 * sensor theft indication , returns json with status text and value that triggered .
 * threshold can be set by command thres 123
 */
#include <lib6lowpan/ip.h>
#include "sensing.h"
#include <Timer.h>
#include "blip_printf.h"

module LightP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;
		interface Timer<TMilli> as SensorReadTimer;

		interface ReadStream<uint16_t> as StreamPar;

		interface ShellCommand as SensitiveCmd;

		interface UDP as TheftSend;
		interface UDP as Settings;

		interface Mount as ConfigMount;
		interface ConfigStorage;
	}
} implementation {

	enum {
		SAMPLE_RATE = 250,
		SAMPLE_SIZE = 10,
		NUM_SENSORS = 1,
	};

	settings_t settings;
	nx_struct sensing_report stats;
	struct sockaddr_in6 route_dest;
	struct sockaddr_in6 multicast;

	
	uint16_t m_parSamples[SAMPLE_SIZE];
	uint32_t sensitivity=100;
	

	event void Boot.booted() {
		//call RadioControl.start();
		//call SensorReadTimer.startPeriodic(SAMPLE_RATE);

		settings.sample_period = 256;
		settings.sample_time = 10000;
		


		route_dest.sin6_port = htons(7000);
		inet_pton6(REPORT_DEST, &route_dest.sin6_addr);

		multicast.sin6_port = htons(4000);
		inet_pton6(MULTICAST, &multicast.sin6_addr);
		call Settings.bind(4000);

		call ConfigMount.mount();

		
	}

	

	task void checkStreamPar() {
		uint8_t i;
		char *reply_buf = call SensitiveCmd.getBuffer(55);
		uint32_t avg = 0;
		uint32_t total=0;

		if (reply_buf != NULL) {
			for (i = 0; i < SAMPLE_SIZE; i++) {
				total=total+m_parSamples[i];
			}
			avg= total/SAMPLE_SIZE;
			
			if (avg < sensitivity){
				call Leds.led0On();
				/*Theft application modified to send a small json string to respective python Listener. 
				structure of json is {status:"Node was stolen", value: light_sensor_value}. One can also just 
				send light value and let python listener generate right message, but just for showing purpose 
				message is generated right on sensor. Sending instead of status one can add ID of node to get 
				exact identify node that is being stolen.
				once can use CSV format or XML , but for readability and small size json seems to be good choice */

				sprintf(reply_buf, "{\"nodeID\":%d ,\"status\":\"Node was stolen\",\"value\": %d }\0\r\n",TOS_NODE_ID,avg);
				call SensitiveCmd.write(reply_buf, 55);

			}	
			else{
				call Leds.led0Off();
				
			}
			printf("Data Sent\n");
		}
		
	}

	event void SensorReadTimer.fired() {
		uint16_t sample_period = 10000; //100HZ
		call StreamPar.postBuffer(m_parSamples, SAMPLE_SIZE);
		call StreamPar.read(sample_period);
		printf("Timer Fired\n");
	}

	
	event void StreamPar.readDone(error_t ok, uint32_t usActualPeriod) {
		if (ok == SUCCESS) {
			post checkStreamPar();
		}
	}

	event void StreamPar.bufferDone(error_t ok, uint16_t *buf,uint16_t count) {}

	
	/*thres command to change sensitivity */
	event char* SensitiveCmd.eval(int argc, char* argv[]) {
		sensitivity= atoi(argv[1]);
	}

	event void RadioControl.startDone(error_t e) {}
	event void RadioControl.stopDone(error_t e) {}
}
