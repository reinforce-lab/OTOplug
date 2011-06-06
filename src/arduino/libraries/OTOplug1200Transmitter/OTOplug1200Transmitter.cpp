/*
 *  OTOplug1200Transmitter.cpp - FSK 1200bps Arduino(TM) software sound modem library
 *  Copyright 2010-2011 REINFORCE lab.
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

#include "OTOplug1200Transmitter.h"

#include <avr/io.h>
#include <avr/interrupt.h>
#include <wiring.h>
#include <util/crc16.h>
#include <stdbool.h>

//#include <HardwareSerial.h>

// single instance of this class
OTOplug1200TransmitterClass OTOplug1200Transmitter;

// **** 
// Parameter definitions
// **** 
// mark1 sampling points per cycle
#define MARK1_DURATION     2
#define MARK0_DURATION     (2 * MARK1_DURATION)
// maxinum number of successible mark1
#define MAX_MARK1_LENGTH 5
// sync charactor
#define SYNC_SYMBOL 0x7e

// IO definitions
/*
#if F_CPU >= 16000000L
// for 16MHz clock
// 8 oversampling. 16MHz / ((44.1kHz / 36) * OVERSAMPLING) = 1632, when clock source is clk/8 -> OCR0A is 1632 / 8 = 204
#define OCR1A_PERIOD 203
// ADC conversion freq is 16MHz / (13 (clock cycles/sample) * 64 (prescaler)) = 19.2k/sec. 
// which is 16 times of FSK base frequency. (it is enough, over sampling rate is 8.)
//(_BV(ADEN)|_BV(ADSC)| B0110), ADEN ADC Enable, 2:0 Prescaler 64
#define ADCSTART (_BV(ADEN)|_BV(ADSC)| 0x06) 
#else
// for 8MHz clock
// 8 oversampling. 8MHz  / ((44.1kHz / 36) * OVERSAMPLING) = 816,  when clock source is clk/8 -> OCR0A is 816  / 8 = 102
#define OCR1A_PERIOD 101
//(_BV(ADEN)|_BV(ADSC)| B0110), ADEN ADC Enable, 2:0 Prescaler 32
#define ADCSTART (_BV(ADEN)|_BV(ADSC)| 0x05) 
#endif
*/
// IO definitions
#if F_CPU >= 16000000L
// for 16MHz clock
// 2 oversampling. 16MHz / ((44.1kHz / 36) * OVERSAMPLING) = 6530, when clock source is clk/64 -> OCR0A is 6530 / 64 = 102
#define OCR1A_PERIOD 102
#else
// for 8MHz clock
#define OCR1A_PERIOD 51
#endif

// **** 
// Interrupt handlers
// **** 
ISR(TIMER1_COMPA_vect)
{
  OTOplug1200Transmitter._invokeInterruptHandler();
}
void OTOplug1200TransmitterClass::_invokeInterruptHandler()
{
  outModulatedSignal();
}

// **** 
// Construcotrs
// **** 
OTOplug1200TransmitterClass::OTOplug1200TransmitterClass() 
{
}
// **** 
// Private methdods
// **** 
void OTOplug1200TransmitterClass::readSendBit()
{
  switch(_frameSenderStatus)   {
  case sendIdle: 
    if(_sendBufLen > 0) {
      _frameSenderStatus = PREAMBLE;
    }
#if OUTPUT_BEAT 
    _isSendingMark1 = true;
#else
    return;
#endif
    break;
  case PREAMBLE:
    _isSendingMark1 = (SYNC_SYMBOL & (0x01 << _sendBufBitPos)) ? true: false;
    _sendBufBitPos++;
    if(_sendBufBitPos >= 8) {
      _sendBufBitPos = 0;
      _ambleCnt++;
      if(_ambleCnt >= NUM_OF_PREAMBLE) {
	_ambleCnt = 0;
	_sendBufIdx   = 0;
	_sendMark1Cnt = 0;
	_frameSenderStatus = DATA;
      }
    }
    break;
  case DATA:
    // should send stuffing bit?
    if(_sendMark1Cnt >= MAX_MARK1_LENGTH) {
      _isSendingMark1 = false;
      _sendMark1Cnt = 0;
    } else {
      // get bit
      _isSendingMark1 = (_sendBuffer[_sendBufIdx] & (0x01 << _sendBufBitPos)) ? true: false;
      _sendBufBitPos++;
      //count mark1 
      _sendMark1Cnt = _isSendingMark1 ? (_sendMark1Cnt +1) : 0;
      // end of byte
      if(_sendBufBitPos >= 8) {
	_sendBufBitPos = 0;
	_sendBufIdx++;      
      }
      // end of buffer
      if(_sendBufIdx >= _sendBufLen) { 
	_frameSenderStatus = POSTAMBLE;
      }
    }
    break;
  case POSTAMBLE:
    // send sync code
    _isSendingMark1 = (SYNC_SYMBOL & (0x01 << _sendBufBitPos)) ? true: false;
    _sendBufBitPos++;
    // is end of preamble?
    if(_sendBufBitPos >= 8) {
      _sendBufBitPos = 0;
      _ambleCnt++;
      // end of packet transmission
      if(_ambleCnt >= NUM_OF_POSTAMBLE) {
	_ambleCnt = 0;
	_sendBufLen = 0; 
	_frameSenderStatus = sendIdle;
      }
    }
    break; 
  default:
    _frameSenderStatus = sendIdle;
  }
}
// this method should be called from the interrupt handler.
void OTOplug1200TransmitterClass::outModulatedSignal()
{
  _modulatePulseCnt--;
  if(_modulatePulseCnt > 0) return;

  // read a bit
  if(_isBusHigh) {
    readSendBit();
  }
  // toggle bus signal
  _modulatePulseCnt = _isSendingMark1 ? (MARK1_DURATION / 2) : (MARK0_DURATION / 2);  
  _isBusHigh = !_isBusHigh;
  
  digitalWrite(MODEM_DOUT_PIN, _isBusHigh); 
}

// **** 
// Public methods
// **** 
void OTOplug1200TransmitterClass::begin()
{
  // Setting Timer0,
  TCCR1A = 0x00; //B00000000;  // OC0A disconnected, OC0B disconnected, CTC mode (TOP OCR1A),
  TCCR1B = 0x0b; //B00001011;  // clock source clk/8, 64
  TCNT1  = 0;
  OCR1A  = OCR1A_PERIOD;
  TIMSK1 = _BV(OCIE1A); // interrupt enable

}
void OTOplug1200TransmitterClass::end()
{
  // TODO (disable Timer1 interrupt...)
}

bool OTOplug1200TransmitterClass::writeAvailable()
{
  return (_sendBufLen == 0);
}

void OTOplug1200TransmitterClass::write(const uint8_t *buf, uint8_t length)
{
  // check whether the buffer is available
  if(_sendBufLen > 0) {
    return;
  } 
  // copy buffer
  uint8_t crc = 0;
  for(int i =0; i < length; i++) {
    crc = _crc_ibutton_update(crc, buf[i]);
    _sendBuffer[i] = buf[i];
  } 
  _sendBuffer[length] = crc;
  _sendBufLen = length + 1;
//Serial.print("setSendQueue:len:");
//Serial.print(_sendBufLen, DEC);
//Serial.print("\n");
}


