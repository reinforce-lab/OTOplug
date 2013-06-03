/*
 *  OTOplug1200Transmitter.cpp - FSK 1200bps Arduino(TM) software sound modem library
 *
 * Copyright 2010-2011 REINFORCE lab.
 * Copyright 2012 WA-FU-U, LLC.
 *
 * Licensed under The MIT license.  (http://www.opensource.org/licenses/mit-license.php)
 */

#include "OTOplug1200Transmitter.h"

#include <avr/io.h>
#include <avr/interrupt.h>
#include <Arduino.h>
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
//#define OCR1A_PERIOD 102
#define OCR1A_PERIOD 102
#else
// for 8MHz clock
#define OCR1A_PERIOD 51
#endif

// ****
// Interrupt handlers
// ****
#if defined(__AVR_ATmega32U4__)
ISR(TIMER4_COMPA_vect)
{
    OTOplug1200Transmitter._invokeInterruptHandler();
}
#else
// Arduino Uno
ISR(TIMER2_COMPA_vect)
{
    OTOplug1200Transmitter._invokeInterruptHandler();
}
#endif

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
    // Setting Timer2,
#if defined(__AVR_ATmega32U4__)
    TCCR4A = 0x00; //B00000000;  // OC0A disconnected, OC0B disconnected, CTC mode (TOP OCR1A),
    TCCR4B = 0x06; //B00000110;  // clock source clk/32 (TBD)
    TCNT4  = 0;
    OCR4C  = OCR1A_PERIOD;
    TIMSK4 = _BV(OCIE4A); // interrupt enable
#else
    // Arduino Uno
    TCCR2A = 0x02; //B00000010;  // OC0A disconnected, OC0B disconnected, CTC mode (TOP OCR1A),
    TCCR2B = 0x04; //B00000100;  // clock source clk/64,
    TCNT2  = 0;
    OCR2A  = OCR1A_PERIOD;
    TIMSK2 = _BV(OCIE2A); // interrupt enable
#endif
    
    // pin mode
    pinMode(MODEM_DOUT_PIN, OUTPUT);
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


