/*
 *  OTOplug1200Transmitter.h - FSK 1200bps Arduino(TM) software sound modem library
 *  Copyright 2010-2011 REINFORCE lab.
 *
 * Copyright 2010-2011 REINFORCE lab.
 * Copyright 2012 WA-FU-U, LLC.
 *
 * Licensed under The MIT license.  (http://www.opensource.org/licenses/mit-license.php) * 
 */

#ifndef OTOplug1200Transmitter_h
#define OTOplug1200Transmitter_h

#include <stddef.h>
#include <inttypes.h>

// ****
// hardware resource allocation
// **** 
// Timer1 : FSK (as a pwm waveform) output generation
// DIO    : D13 is used to output FSK signal
#define MODEM_DOUT_PIN 13

// version of this library
#define OTOplug1200Transmitter_VERSION 1 

// **** 
// FSK parameter definitions
// **** 
#define OUTPUT_BEAT true
#define NUM_OF_PREAMBLE  1
#define NUM_OF_POSTAMBLE 1
#define MAX_PACKET_SIZE  128

typedef enum frameSenderStatus      { sendIdle = 0, PREAMBLE =1, DATA=2, POSTAMBLE =3 } frameSenderStatusType;

class OTOplug1200TransmitterClass
{
 private:
  // uint8_t sender
  bool _isBusHigh;
  bool _isSendingMark1;
  int8_t _modulatePulseCnt;

  // frame sender
  frameSenderStatusType _frameSenderStatus;
  uint8_t _sendBuffer[MAX_PACKET_SIZE];
  uint8_t _sendBufLen;
  uint8_t _sendBufIdx;
  uint8_t _sendMark1Cnt;  
  uint8_t _sendBufBitPos;
  uint8_t _ambleCnt;

  uint8_t _sendUint8_TPos, _sendBitPos;

  // private methods
  void readSendBit();
  void outModulatedSignal();

 public:  
  OTOplug1200TransmitterClass();

  void begin();
  void end();

  // this method is invoked from the interrupt handler. user must not invoke this.
  void _invokeInterruptHandler();

  bool writeAvailable();
  void write(const uint8_t *buf, uint8_t size);
};

// instance of this class (singleton is required to handle an timer interruption.)
extern OTOplug1200TransmitterClass OTOplug1200Transmitter;

#endif

