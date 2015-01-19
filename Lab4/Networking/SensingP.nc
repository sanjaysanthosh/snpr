
/*
 *@author: sanjeet raj pandey
 *group 2
 *The endiness problem 
 * Excercise 4.4
 */

#include <lib6lowpan/ip.h>
#include "sensing.h"

module SensingP {
	uses {
		interface Boot;
		interface Leds;
		interface SplitControl as RadioControl;
		interface UDP as SenseSend;
		interface UDP as LightSend;
		interface Timer<TMilli> as SenseTimer;
		interface Read<uint16_t> as Humidity;
		interface Read<uint16_t> as Light;

	}

} implementation {

	enum {
		SENSE_PERIOD = 128, // ms
	};

	nx_struct sensing_report stats; 
	nx_struct sensing_report_light statsl;//stat for light
	struct sockaddr_in6 route_dest, route_dest_light;
	m_humidity = 0;
	m_light=0;

	event void Boot.booted() {
		call RadioControl.start();
	}

	event void RadioControl.startDone(error_t e) {
		route_dest.sin6_port = htons(7000);
		route_dest_light.sin6_port=htons(8000);
		inet_pton6(REPORT_DEST, &route_dest.sin6_addr);
		inet_pton6(REPORT_DEST, &route_dest_light.sin6_addr);


		call SenseTimer.startPeriodic(SENSE_PERIOD);

	}

	task void report_humidity() {
		stats.seqno++;
		stats.sender = TOS_NODE_ID;
		stats.humidity = m_humidity;
		call SenseSend.sendto(&route_dest, &stats, sizeof(stats));
	}

	/*Place a task to scheduler for sending lightsensor once it is read*/
	task void report_light(){
		statsl.seqno++;
		statsl.sender = TOS_NODE_ID;
		statsl.light = m_light;
		call SenseSend.sendto(&route_dest_light, &statsl, sizeof(statsl));
	}

	event void SenseSend.recvfrom(struct sockaddr_in6 *from, 
			void *data, uint16_t len, struct ip6_metadata *meta) {}
	event void LightSend.recvfrom(struct sockaddr_in6 *from, 
			void *data, uint16_t len, struct ip6_metadata *meta) {}

	event void SenseTimer.fired() {
		call Humidity.read();
		/*make periodic read of light sensor*/
		call Light.read();
	}

	event void Light.readDone(error_t ok, uint16_t val) {
		if (ok == SUCCESS) {
			m_light = val;
			/*place a task after Sensor been read*/
			post report_light();
		}
	}

	event void Humidity.readDone(error_t ok, uint16_t val) {
		if (ok == SUCCESS) {
			m_humidity = val;
			post report_humidity();
		}
	}

	event void RadioControl.stopDone(error_t e) {}
}
