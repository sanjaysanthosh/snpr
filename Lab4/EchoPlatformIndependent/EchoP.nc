/*
 *@author: sanjeet raj pandey
 *group 2
 *The endiness problem 
 * Excercise 4.2
 */

#include <lib6lowpan/ip.h>
#include <ctype.h>
#include <lib6lowpan/nwbyte.h>
#include "blip_printf.h"

module EchoP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;

		interface UDP as Echo;
	}
} implementation {

	event void Boot.booted() {
		call RadioControl.start();
		call Echo.bind(7);
		call Leds.led1On();
	}

	event void Echo.recvfrom(struct sockaddr_in6 *from, void *data,
			  uint16_t len, struct ip6_metadata *meta) {
		char* str = data;
		//platform indepent type added as default data type that would be sent.
		// in this case nx_unit16_t as big endian 16 bit value
		nx_uint16_t i; 

		bool isNumber = TRUE;
		char* ss;

		for (i = 0; i < len - 1; i++) {
			if (!isdigit(str[i])) {
				isNumber = FALSE;
				break;
			}
		}

		if (isNumber) {

			i = atoi(str);
			call Echo.sendto(from, &i , sizeof(nxle_uint16_t));
		} else { 
			call Echo.sendto(from, data, len);
		}
	}



	event void RadioControl.startDone(error_t e) {}

	event void RadioControl.stopDone(error_t e) {}  
}
