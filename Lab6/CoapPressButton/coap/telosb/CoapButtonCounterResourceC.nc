/*
 *@author: sanjeet raj pandey
 *Group 2
 */
#include <UserButton.h>
generic configuration CoapButtonCounterResourceC(uint8_t uri_key) {
    provides interface CoapResource;
    //uses interface Leds;
} implementation {
    components new CoapButtonCounterResourceP(uri_key) as CoapButtonCounterResourceP;

    CoapResource = CoapButtonCounterResourceP;
    //Leds = CoapButtonCounterResourceP;

	components MainC;
	CoapButtonCounterResourceP.Boot -> MainC;

	components UserButtonC;
	CoapButtonCounterResourceP.Get -> UserButtonC;
	CoapButtonCounterResourceP.Notify -> UserButtonC;

	//components new TimerMilliC();
	//CoapLedResourceP.Timer -> TimerMilliC;


}
