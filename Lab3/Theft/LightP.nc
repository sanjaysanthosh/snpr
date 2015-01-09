#include <lib6lowpan/ip.h>

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
	}
} implementation {

	enum {
		SAMPLE_RATE = 1000,
		SAMPLE_SIZE = 10,
		NUM_SENSORS = 1,
	};

	
	uint16_t m_parSamples[SAMPLE_SIZE];
	uint32_t sensitivity=100;
	

	event void Boot.booted() {
		call RadioControl.start();
		call SensorReadTimer.startPeriodic(SAMPLE_RATE);
		
	}

	

	task void checkStreamPar() {
		uint8_t i;
		char *reply_buf = call SensitiveCmd.getBuffer(50);
		uint32_t avg = 0;
		uint32_t total=0;

		if (reply_buf != NULL) {
			for (i = 0; i < SAMPLE_SIZE; i++) {
				total=total+m_parSamples[i];
			}
			avg= total/SAMPLE_SIZE;
			//sprintf(reply_buf, "%ld %d\r\n", avg, sensitivity);
			if (avg < sensitivity){
				call Leds.led0On();
				sprintf(reply_buf, "Node being stolen [ %d]\r\n",avg);
				call SensitiveCmd.write(reply_buf, 50);

			}	
			else{
				call Leds.led0Off();
				
			}
		}
		
	}

	event void SensorReadTimer.fired() {
		uint16_t sample_period = 10000; //100HZ
		call StreamPar.postBuffer(m_parSamples, SAMPLE_SIZE);
		call StreamPar.read(sample_period);
	}

	
	event void StreamPar.readDone(error_t ok, uint32_t usActualPeriod) {
		if (ok == SUCCESS) {
			post checkStreamPar();
		}
	}

	event void StreamPar.bufferDone(error_t ok, uint16_t *buf,uint16_t count) {}

	
	event char* SensitiveCmd.eval(int argc, char* argv[]) {
		sensitivity= atoi(argv[1]);
	
	}

	event void RadioControl.startDone(error_t e) {}
	event void RadioControl.stopDone(error_t e) {}
}
