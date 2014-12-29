/*
 *@author: sanjeet raj apndey
 */
 /*
  *This is interface for Binary counter .
  */
interface BinCounter{
	
	/*Start on this command counting*/
	command void start();
	
	/*Stops the counting when this command is called*/
	command void stop();

	/*event raised when counting is done*/
	event void completed();
}