/*
 *@author: sanjeet raj pandey
 *Group 2
 */
#include <pdu.h>
#include <async.h>
#include <mem.h>
#include <ctype.h>
#include <resource.h>
#include <stdio.h>

/*
Following the features from Exercise 6.1 and Exercise 6.2 , this Exercise 6.3 is addition where we are setting
also the node name and sending in format of nodelabel:countbuttonpressed . For this we have enabled POST method as well.
Label is sent on vis post and is saved in variable name[64]. 
*/


generic module CoapButtonCounterResourceP(uint8_t uri_key) {
  provides interface CoapResource;
  //uses interface Leds;
  uses interface Boot;
  uses interface Get<button_state_t>;
  uses interface Notify<button_state_t>;
  //interface Timer<TMilli>;

} implementation {
  char name[64]={'n','a','m','e'};
  uint16_t countButtonPressed=0;
  coap_pdu_t *response;
 bool observeState=FALSE;
  coap_pdu_t *temp_request;
  bool lock = FALSE; //TODO: atomic
  coap_async_state_t *temp_async_state = NULL;
  coap_resource_t *temp_resource = NULL;
  unsigned int temp_content_format;
  int datalen = 0;
  char databuf[8];

  command error_t CoapResource.initResourceAttributes(coap_resource_t *r) {
    return SUCCESS;
  }

  event void Boot.booted() {
    call Notify.enable();
   // snprintf(name, sizeof(name), "button", 1);
    
  }



  event void Notify.notify( button_state_t state ) {
    
    if ( state == BUTTON_PRESSED ) {
      countButtonPressed++;

      if(observeState){
          response = coap_new_pdu();
          response->hdr->code = COAP_RESPONSE_CODE(205);
          temp_resource->dirty = 1;

        if (temp_resource->data != NULL) {
            coap_free(temp_resource->data);
        }

       
       
        datalen= snprintf(databuf, sizeof(name) + sizeof(databuf), "%s:%i", name,countButtonPressed);

        if ((temp_resource->data = (uint8_t *) coap_malloc(datalen)) != NULL) {
          
        
         
          memcpy(temp_resource->data, databuf, datalen);
          temp_resource->data_len = datalen;
          temp_resource->data_ct = temp_content_format;
        }
        
        signal CoapResource.notifyObservers();

      }
     
    } else if ( state == BUTTON_RELEASED ) {
      
    }
  }

 

  /////////////////////
  // GET:
  task void getMethod() {

    int datalen = 0;
  

    uint16_t val = countButtonPressed;

    datalen= snprintf(databuf, sizeof(name) + sizeof(databuf), "%s:%i", name,val);


    response = coap_new_pdu();
    response->hdr->code = COAP_RESPONSE_CODE(205);
    
    #ifndef WITHOUT_OBSERVE
    if (temp_async_state->flags & COAP_ASYNC_OBSERVED){
        
        observeState = !observeState;
         
    }
    #endif
    
    if (temp_resource->data != NULL) {
      coap_free(temp_resource->data);
    }
    if ((temp_resource->data = (uint8_t *) coap_malloc(datalen)) != NULL) {
      memcpy(temp_resource->data, databuf, datalen);
      temp_resource->data_len = datalen;
    } else {
      response->hdr->code = COAP_RESPONSE_CODE(500);
    }

  
    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);
    lock = FALSE;
  }

  command int CoapResource.getMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {
    if (lock == FALSE) {
      lock = TRUE;

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = content_format;

      post getMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_503;
    }
  }

  /////////////////////
  // PUT:
  task void putMethod() {
    size_t size;
    unsigned char *data;
    

    response = coap_new_pdu();
//&size
    coap_get_data(temp_request,sizeof(uint16_t) , &data);
    
    countButtonPressed=atoi(data);
    
    

    response->hdr->code = COAP_RESPONSE_CODE(204);

    signal CoapResource.methodDone(SUCCESS,
				   temp_async_state,
				   temp_request,
				   response,
				   temp_resource);
    lock = FALSE;
  }

  command int CoapResource.putMethod(coap_async_state_t* async_state,
				     coap_pdu_t* request,
				     coap_resource_t *resource,
				     unsigned int content_format) {
    if (lock == FALSE) {
      lock = TRUE;

      temp_async_state = async_state;
      temp_request = request;
      temp_resource = resource;
      temp_content_format = content_format;

      post putMethod();
      return COAP_SPLITPHASE;
    } else {
      return COAP_RESPONSE_CODE(503);
    }
  }

  task void postMethod(){

    size_t size;
    unsigned char *data;
    

    response = coap_new_pdu();

    coap_get_data(temp_request,&size , &data);
    
    
    datalen=snprintf(name, size+1, "%s\0", data);
    response->hdr->code = COAP_RESPONSE_CODE(204);

    signal CoapResource.methodDone(SUCCESS,
           temp_async_state,
           temp_request,
           response,
           temp_resource);
    lock = FALSE;
  }

  command int CoapResource.postMethod(coap_async_state_t* async_state,
				      coap_pdu_t* request,
				      coap_resource_t *resource,
				      unsigned int content_format) {
            if (lock == FALSE) {
                  lock = TRUE;

                  temp_async_state = async_state;
                  temp_request = request;
                  temp_resource = resource;
                  temp_content_format = content_format;

                  post postMethod();
                  return COAP_SPLITPHASE;
                } else {
                  return COAP_RESPONSE_CODE(503);
                }
  }

  command int CoapResource.deleteMethod(coap_async_state_t* async_state,
					coap_pdu_t* request,
					coap_resource_t *resource) {
    return COAP_RESPONSE_405;
  }
}
