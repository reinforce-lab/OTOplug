/*
 * OTOplug1200Test.pde - FSK 1200bps software modem test sketch
 * Text send to Serial port is echo back as a modulated modem signal.
 * 
 *  Copyright 2010-2011 REINFORCE lab.
 *  Copyright 2012 WA-FU-U, LLC.
 *
 * Licensed under The MIT license.  (http://www.opensource.org/licenses/mit-license.php)
 *
 */

#include <OTOplug1200.h>

// ****
// Variables
// ****
uint8_t sendBuf[MAX_PACKET_SIZE];
bool shouldSendInitializedMessage;
// ****
// Definitions
// ****

// ****
// methods
// ****
void setup()
{
  Serial.begin(115200);
  Serial.println("start");
  OTOplug1200.begin();
}
void loop()
{ 
  if(!OTOplug1200.writeAvailable()) return;  
  int numBytes = Serial.available();
  /*  
   delay(15);
   {
   sendBuf[0] = 0x00;
   OTOplug1200.write(sendBuf,1);
   }
   */

  if(numBytes > 0) {
    // build a packet
    for(int i = 0; i < numBytes ; i++) {
      sendBuf[i] = Serial.read();
    }
    sendBuf[numBytes] = 0; // end of string 
    // send to serial port

    OTOplug1200.write(sendBuf, numBytes);

    // echo back
    Serial.write('<');
    Serial.print(numBytes);
    Serial.print(':');     
    for(int i=0; i < numBytes; i++){ 
      Serial.print(sendBuf[i], HEX);
      Serial.print(",");
    }
    Serial.println();
  }
}


