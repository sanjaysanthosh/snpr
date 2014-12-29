/*
 *@author: sanjeet raj apndey
 * ShellDemoP extended to set leds as binary representation of given number via radio
 */
#include "blip_printf.h"
module ShellDemoP {
	uses {
		interface Boot;
		interface SplitControl as RadioControl;
		interface ShellCommand as DemoCmd;
		interface ShellCommand as SetCmd;
		interface Leds as Led;
	}
} implementation {

	event void Boot.booted() {
		call RadioControl.start();
	}

	event char* DemoCmd.eval(int argc, char* argv[]) {
		char* reply_buf = call DemoCmd.getBuffer(32);	
		strcpy(reply_buf, "Hello World!\n");		
		return reply_buf;
	}

	/*this event takes 1st argument and sets led sequence as of its binary value.
	 *Since we are only reading 1 byte we take first byte from argument 1
	 */

	event char* SetCmd.eval(int argc,char* argv[]){
		char* reply_buf = call SetCmd.getBuffer(4);
		uint8_t c = (uint8_t)argv[1][0];	
		printf("CHECK: %u\n",c);	
		/*check for valid number from 0 to 7 */
		if(c > 55 || c < 48){
			
			strcpy(reply_buf, "Allwed[0-7]!\n");
		}else{

			call Led.set(c);
			strcat(argv[1],"\n");
			strcpy(reply_buf, argv[1]);
		}
		
		return reply_buf;

	}

	event void RadioControl.startDone(error_t e) {}
	event void RadioControl.stopDone(error_t e) {}
}
