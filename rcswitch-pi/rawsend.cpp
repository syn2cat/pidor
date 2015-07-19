/*
 Usage: ./send  <bitlen>  <command>
 bitlen is in microsecond
 Command is 0 for OFF and 1 for ON
 */

#include "RCSwitch.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char *argv[]) {

 /*
 output PIN is hardcoded for testing purposes
 see https://projects.drogon.net/raspberry-pi/wiringpi/pins/
 for pin mapping of the raspberry pi GPIO connector
 */
 int PIN = 2; // GPIO-PIN 17
 char pSystemCode[14];
 int bitlen=atoi(argv[1]);
 char* sendptr=argv[2];

 if (wiringPiSetup () == -1) return 1;
 printf("sending with bitlength %d the data %s ...\n", bitlen, argv[2]);
 RCSwitch mySwitch = RCSwitch();
 printf("defining transmit PIN[%i] ... ",PIN);
 mySwitch.enableTransmit(PIN);
 printf("success\n");


 int i=0;
 while(sendptr[i]!= (char)0)
 {
   printf("%c",sendptr[i]);
   fflush(stdout);
   if(sendptr[i] == '0')
   {
      digitalWrite(PIN, LOW);
   }
   if(sendptr[i] == '1')
   {
      digitalWrite(PIN, HIGH);
   }
   delayMicroseconds( bitlen );
   i++;
 }
 printf("\ndone\n");
}
