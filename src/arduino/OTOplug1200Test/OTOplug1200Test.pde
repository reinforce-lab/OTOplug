/*
 * OTOplug1200Test.pde - FSK 1200bps software modem test sketch
 * Text send to Serial port is echo back as a modulated modem signal.
 * 
 * Copyright 2010-2011 REINFORCE lab.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
      Serial.write(':');
      Serial.write(sendBuf, numBytes);
      Serial.println();
  }
}

