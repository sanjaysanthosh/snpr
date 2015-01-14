/*
 *@author: sanjeet raj pandey
 * Bin counter module counts till binary 4 and then signal as well as reset counting
 * One thing to note is Binary is displayed by combination of LED using the interval time sequence
 */

module BinCounterP {

	provides interface BinCounter;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Timer<TMilli> as Timer2;
	uses interface Leds;

	
} implementation{

	int c =0;

	event void Timer0.fired()
	{
	    dbg("BlinkC", "Timer 0 fired @ %s.\n", sim_time_string());
	    call Leds.led0Toggle();
		c = call Leds.get();
		/*Counts till 3 starting from 0 and  reset as well as signal counting completed*/
	   	if(c > 4) { c=0; signal BinCounter.completed();}
	}
	  
	event void Timer1.fired()
	{
	    dbg("BlinkC", "Timer 1 fired @ %s \n", sim_time_string());
	    call Leds.led1Toggle();
	    
	}
	  
	event void Timer2.fired()
	{
	    dbg("BlinkC", "Timer 2 fired @ %s.\n", sim_time_string());
	    call Leds.led2Toggle();
	   	
	}
	/*Command to start counting */
	command void BinCounter.start(){
		call Leds.set(0);
		call Timer0.startPeriodic( 250 );
	    call Timer1.startPeriodic( 500 );
	    call Timer2.startPeriodic( 1000 );

	}
	/*Command to stop counting */
	command void BinCounter.stop(){

		call Timer0.stop();
	    call Timer1.stop();
	    call Timer2.stop();
	    call Leds.set(0);

	}

}
