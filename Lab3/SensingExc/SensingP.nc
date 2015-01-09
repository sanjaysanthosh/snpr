#include <stdio.h>
#include <lib6lowpan/ip.h>

module SensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface Timer<TMilli> as SenseTimer;
		interface Read<uint16_t> as LightPar;
		interface ShellCommand as ReadParCmd;
	}
} implementation {
	

	enum {
		Read_PERIOD = 250, // ms
		LightPar_THRESHOLD = 0x10,
	};

	event void Boot.booted() {
		call RadioControl.start();
		call SenseTimer.startPeriodic(Read_PERIOD);
	}

	event void SenseTimer.fired() {
		//call LightPar.read();
		
	}

	event void LightPar.readDone(error_t e, uint16_t val) {

		uint32_t max_reply_len = 50;
		char *reply_buf = call ReadParCmd.getBuffer(max_reply_len);
		uint32_t len;
		if (e == SUCCESS){
			if (val < LightPar_THRESHOLD){
				call Leds.led0On();
				//shadow

			}	
			else{
				call Leds.led0Off();
				//no shadow
			}

			/*Exercise 3.1*/
			len = snprintf(reply_buf, max_reply_len, "[value: %d]\n",val);
			call ReadParCmd.write(reply_buf,max_reply_len);
		}
	}


	event char* ReadParCmd.eval(int argc,char* argv[]){
		//char* reply_buf = call ReadParCmd.getBuffer(32);	
		//strcpy(reply_buf, "[value: %u]\n",);		
		//return reply_buf;
		call LightPar.read();
	}



	event void RadioControl.startDone(error_t e) {}

	event void RadioControl.stopDone(error_t e) {}
}
