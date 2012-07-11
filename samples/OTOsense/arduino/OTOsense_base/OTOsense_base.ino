/*
 * OTOsense_base.ino - iPhone sensor shield base sketch
 * Copyright (C) 2012 REINFORCE Lab. All rights reserved.
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the MIT license.
 *
 */

#include <OTOReceiver1200.h>

// ****
// 定義
// ****
#define SERIAL_DEBUG 1
#if SERIAL_DEBUG
#endif

// ****
// 変数
// ****
uint8_t rcvBuf[MAX_PACKET_SIZE];
uint8_t rcvLength;

// packet receiver method
void packetReceivedCallback(const uint8_t *buf, uint8_t length)
{
  if(length == 0 || rcvLength != 0) return;
 
  // copy buffer
  for(int i=0; i < length; i++) {
    rcvBuf[i] = buf[i];
  }
  rcvLength = length;
}

// packet dump 
#if SERIAL_DEBUG
void packetDump(const uint8_t *buf, uint8_t length)
{  
  Serial.print("Packet(len:");
  Serial.print(length, DEC);
  Serial.print(")");
  
  for(int i=0; i < length; i++) {
    Serial.print(", ");
    Serial.print(buf[i], HEX);
  }
  Serial.println("");
}
#endif

void setup()
{
#if SERIAL_DEBUG
  Serial.begin(115200);
  Serial.println("Start:");
#endif

  for(int i = 2; i < 12; i++) {
   pinMode(i, INPUT_PULLUP);
  }
  
  OTOReceiver1200.begin();
  OTOReceiver1200.attach(packetReceivedCallback);
}
void loop()
{ 
  if(rcvLength == 0) return;

#if SERIAL_DEBUG
 packetDump(rcvBuf, rcvLength);
#endif
  rcvLength = 0;
}

