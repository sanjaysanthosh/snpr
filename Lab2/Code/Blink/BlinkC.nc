
/*
 *@author: sanjeet raj pandey
 * This is module wired to start on booting , it implements Bincounter to Start and reset on signal 
 */
#include "Timer.h"

module BlinkC @safe()
{
  uses interface Boot;
  uses interface BinCounter as Counter;

  
} implementation
{
  event void Boot.booted()
  {
    call Counter.start();
  }

  event void Counter.completed(){

    dbg("BlinkC", "Timer Overflown:Resetting");
    call Counter.stop();
    call Counter.start();
  }

  
}

