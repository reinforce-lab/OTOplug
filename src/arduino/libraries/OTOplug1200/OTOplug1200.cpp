/*
 *  OTOplug1200.cpp - FSK 1200bps Arduino(TM) software sound modem library
 *
 *  Copyright 2010-2011 REINFORCE lab.
 *  Copyright 2012 WA-FU-U, LLC.
 *
 * Licensed under The MIT license.  (http://www.opensource.org/licenses/mit-license.php)
 */

#include "OTOplug1200.h"

#include <avr/io.h>
#include <avr/interrupt.h>
#include <Arduino.h>
#include <util/crc16.h>
#include <stdbool.h>

//#include <HardwareSerial.h>

// single instance of this class
OTOplug1200Class OTOplug1200;

// ****
// Parameter definitions
// ****
// analog reference of ADMUX (B01000000) AVCC with external cap at AREF pin.
#define ANALOG_REFERENCE 0x40
// threshold level (5mv/unit)
#define SIG_THRESHOLD 50
// low pass filter time constant is  32 (~ 2^5)
#define LPF_BIT_SHIFT 5
// mark1 sampling points per cycle
#define MARK1_DURATION     8
#define MARK0_DURATION     (2 * MARK1_DURATION)
//#define MAX_MARK0_DURATION (3 * MARK1_DURATION)
//#define FSK_SAMPLING_TIME  5
#define FSK_PULSE_WIDTH_THRESHOLD (1.5 * MARK1_DURATION)
#define FSK_LOST_CARRIER_DURATION (1.5 * MARK0_DURATION)
// maxinum number of successible mark1
#define MAX_MARK1_LENGTH 5
// sync charactor
#define SYNC_SYMBOL 0x7e

// IO definitions
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

// ****
// Interrupt handlers
// ****
#if defined(__AVR_ATmega32U4__)
ISR(TIMER4_COMPA_vect)
{
    OTOplug1200._invokeInterruptHandler();
}
#else
// Arduino Uno
ISR(TIMER2_COMPA_vect)
{
    OTOplug1200._invokeInterruptHandler();
}
#endif

void OTOplug1200Class::_invokeInterruptHandler()
{
    // Reading ADC
    uint8_t high, low;
    low  = ADCL;
    high = ADCH;
    int adc_value = (high << 8) | low;
    //  Serial.println(adc_value, DEC);
    
    switch(_analogPinReadingStat)  {
        case startReading:
            // set ADMUX
            ADMUX  = ANALOG_REFERENCE | _analogPinNumber; //B01000000; // AVcc with external capactor at AREF pin, ADC0
            _analogPinReadingStat = changedADMUX;
            break;
        case changedADMUX:
            // read analog value
            _analogPinValue = adc_value;
            adc_value = (_lpf_sig >> 5); // replace modem signal with lpf output signal
            ADMUX  = ANALOG_REFERENCE | _modem_pin; //B01000000; // AVcc with external capactor at AREF pin, ADC0
            _analogPinReadingStat = analogValueAvailable;
            break;
        case analogValueAvailable:
            break;
        case modemSampling:
            break;
        default:
            _analogPinReadingStat = modemSampling;
    }
    
    // kick analog-to-digital conversion
    ADCSRA = ADCSTART; // kick ADC
    
    // HPF filter
    int diff;
    diff = (adc_value << 5) - _lpf_sig;
    _lpf_sig += (diff >> LPF_BIT_SHIFT);
    diff >>= 5;
    
    // edge detection
    bool edgeDetection = false;
    if(_sigLevel) {
        if(diff < -1 * SIG_THRESHOLD) {
            edgeDetection = true;
            _sigLevel = false;
        }
    } else {
        if(diff > SIG_THRESHOLD) {
            edgeDetection = true;
            _sigLevel = true;
        }
    }
    
    // bit decoding
    if(edgeDetection) {
        bool isNarrowPulse = (_clock < (FSK_PULSE_WIDTH_THRESHOLD /2));
        _lostCarrier = false;
        _clock = 0;
        _pllPhase++;
        if(_pllPhase >= 2) {
            if(_isPreviousPulseNarrow && isNarrowPulse) {
                // set mark1
                //Serial.println("1");
                _pllPhase = 0;
                byteDecode(true);
            } else if(!_isPreviousPulseNarrow && !isNarrowPulse) {
                // set mark0
                //Serial.println("0");
                _pllPhase = 0;
                byteDecode(false);
            }
        }
        _isPreviousPulseNarrow = isNarrowPulse;
    }
    _clock++;
    
    // lost carrier?
    if(!_lostCarrier && _clock == FSK_LOST_CARRIER_DURATION) {
        _lostCarrier = true;
        lostCarrier();
    }
    
    outModulatedSignal();
}

// ****
// Construcotrs
// ****
OTOplug1200Class::OTOplug1200Class()
{
}
// ****
// Private methdods
// ****
void OTOplug1200Class::byteDecode(bool isMark1)
{
    // bit shifter
    _decodingBitLength++;
    _decodingData >>= 1;
    if(isMark1) {
        _decodingData |= 0x8000;
        _mark1Cnt++;
    } else {
        _decodingData &= 0x7fff;
        _mark1Cnt = 0;
    }
    // byte decoding
    switch(_byteDecodingStatus) {
        case START:
            //Serial.println(_decodingData, BIN);
            if(_decodingBitLength >= 8 &&  (_decodingData >> 8) == SYNC_SYMBOL) {
                _byteDecodingStatus = ReadingBit;
                _decodingBitLength = 0;
                //Serial.println("START->SYN");
            }
            break;
        case ReadingBit:
            if(_decodingBitLength >= 8) {
                receiveByte( (uint8_t)(_decodingData >> 8) );
                _decodingBitLength = 0;
                //Serial.println(_decodingData);
            }
            if(_mark1Cnt >= MAX_MARK1_LENGTH) {
                //Serial.println("ReadingBit->StuffingBit");
                _byteDecodingStatus = StuffingBit;
            }
            break;
        case StuffingBit:
            if(isMark1) {
                //Serial.println("StuffingBit->SYN");
                _byteDecodingStatus = START;
                endOfFrame();
            } else {
                //Serial.println("StuffingBit->ReadingBit");
                _byteDecodingStatus = ReadingBit;
                _decodingBitLength--;
                _decodingData <<= 1; // eliminate a stuffing bit
            }
            break;
        default:
            _byteDecodingStatus = START;
            break;
    }
}
void OTOplug1200Class::lostCarrier() {
    _byteDecodingStatus = START;
    endOfFrame();
}
// Frame data receiver
void OTOplug1200Class::receiveByte(uint8_t data)
{
    if(data == SYNC_SYMBOL) { endOfFrame(); }
    _rcvBuf[_rcvLength++] = data;
    _crcChecksum  = _crc_ibutton_update(_crcChecksum, data);
    if(_rcvLength >= MAX_PACKET_SIZE)  { endOfFrame(); }
}
void OTOplug1200Class::endOfFrame()
{
    if(_rcvLength == 0) return;
    
    if(IgnoreCRCCheckSum || _crcChecksum == 0) {
        (*currentReceiveCallback)(_rcvBuf, _rcvLength -1);
    }
    
    // error packet dump code
    /*
     if(_crcChecksum != 0) {
     Serial.print("CRC error: Packet len:");
     Serial.print(_rcvLength, DEC);
     Serial.print(" ");
     uint8_t crc = 0;
     for(int i=0; i < _rcvLength; i++) {
     Serial.print(", ");
     Serial.print(_rcvBuf[i], HEX);
     crc = _crc_ibutton_update(crc, _rcvBuf[i]);
     }
     Serial.print(" expeced crc:");
     Serial.println((int)crc, HEX);
     }
     */
    _crcChecksum = 0;
    _rcvLength = 0;
}
void OTOplug1200Class::readSendBit()
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
void OTOplug1200Class::outModulatedSignal()
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
void OTOplug1200Class::begin()
{
    // Setting Timer2,
#if defined(__AVR_ATmega32U4__)
    TCCR4A = 0x00; //B00000000;  // OC0A disconnected, OC0B disconnected, CTC mode (TOP OCR1A),
    TCCR4B = 0x03; //B00000100;  // clock source clk/8, (TBD)
    TCNT4  = 0;
    OCR4C  = OCR1A_PERIOD;
    TIMSK4 = _BV(OCIE4A); // interrupt enable
#else
    // Arduino Uno
    TCCR2A = 0x02; //B00000010;  // OC0A disconnected, OC0B disconnected, CTC mode (TOP OCR1A),
    TCCR2B = 0x0a; //B00001010;  // clock source clk/8,
    TCNT2  = 0;
    OCR2A  = OCR1A_PERIOD;
    TIMSK2 = _BV(OCIE2A); // interrupt enable
#endif
    
    // analog pin
#if defined(__AVR_ATmega32U4__)
    _modem_pin = analogPinToChannel(MODEM_DIN_PIN);
#else
    _modem_pin = MODEM_DIN_PIN;
#endif
    
    // pin mode
    pinMode(MODEM_DOUT_PIN, OUTPUT);
    
    // Setting ADC
    ADMUX  = ANALOG_REFERENCE | _modem_pin; //B01000000; // AVcc with external capactor at AREF pin, ADC0
    ADCSRA = ADCSTART;
}
void OTOplug1200Class::end()
{
    // TODO (disable Timer1 interrupt...)
}

// send a request to read an analog pin
void OTOplug1200Class::startADConversion(uint8_t pin_number)
{
    if(_analogPinReadingStat == modemSampling) {
#if defined(__AVR_ATmega32U4__)
        _analogPinNumber = analogPinToChannel(pin_number);
#else
        _analogPinNumber = pin_number;
#endif
        _analogPinReadingStat = startReading;
    }
}
// reading analog pin value , true if value is valid
bool OTOplug1200Class::readAnalogPin(uint8_t *pinum, uint16_t *value)
{
    if(_analogPinReadingStat != analogValueAvailable) return false;
    
    *pinum = _analogPinNumber;
    *value = _analogPinValue;
    _analogPinReadingStat = modemSampling;
    
    return true;
}

bool OTOplug1200Class::writeAvailable()
{
    return (_sendBufLen == 0);
}

void OTOplug1200Class::write(const uint8_t *buf, uint8_t length)
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
void OTOplug1200Class::attach(receiveCallbackFunction fnc)
{
    currentReceiveCallback = fnc;
}

