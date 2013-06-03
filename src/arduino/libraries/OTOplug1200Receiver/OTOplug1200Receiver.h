/*
 *  OTReceiver1200.h - FSK 1200bps Arduino(TM) software sound modem library
 *  Copyright 2010-2012 REINFORCE lab.
 *
 *  Copyright 2010-2011 REINFORCE lab.
 *  Copyright 2012 WA-FU-U, LLC.
 *
 * Licensed under The MIT license.  (http://www.opensource.org/licenses/mit-license.php)
 *
 */

#ifndef OTOplug1200_h
#define OTOplug1200_h

#include <stddef.h>
#include <inttypes.h>

// ****
// hardware resource allocation
// ****
// Timer1 : FSK (as a pwm waveform) output generation
// ADC    : AD0 is used to capture FSK signal
#define MODEM_DIN_PIN  0

// version of this library
#define OTOplug1200Receiver_VERSION 1

// ****
// FSK parameter definitions
// ****
#define MAX_PACKET_SIZE 128

// callback function types
extern "C" {
    typedef void (*receiveCallbackFunction)(const uint8_t *, uint8_t);
    //  typedef void (*bufferEmptyCallbackFunction)(void);
}

typedef enum byteDecoderStatus      { START = 0, ReadingBit = 1, StuffingBit = 2 } byteDecoderStatusType;
typedef enum analogPinReadingStatus { modemSampling=0, startReading=1, changedADMUX=2, analogValueAvailable} analogPinReadingStatusType;
class OTOplug1200ReceiverClass
{
private:
    // variables of an input signal filter
    int _lpf_sig;
    bool _sigLevel;
    uint8_t _clock;
    uint8_t _pllPhase;
    bool _lostCarrier;
    bool _isPreviousPulseNarrow;
    
    // analog pin assignments
    uint8_t _modem_pin;
    
    // uint8_t decoder
    byteDecoderStatusType _byteDecodingStatus;
    uint16_t _decodingData;
    uint8_t _decodingBitLength;
    uint8_t _mark1Cnt;
    
    // frame  decoder
    uint8_t _crcChecksum;
    uint8_t _rcvLength;
    uint8_t _rcvBuf[MAX_PACKET_SIZE];
    
    // analog pin functions
    analogPinReadingStatusType _analogPinReadingStat;
    uint8_t _analogPinNumber;
    uint16_t _analogPinValue;
    
    // callback functions
    receiveCallbackFunction currentReceiveCallback;
    
    // private methods
    void byteDecode(bool isMark1);
    void lostCarrier();
    
    void endOfFrame();
    void receiveByte(uint8_t data);
    
public:
    bool IgnoreCRCCheckSum;
    
    OTOplug1200ReceiverClass();
    
    void begin();
    void end();
    
    // this method is invoked from the interrupt handler. user must not invoke this.
    void _invokeInterruptHandler();
    
    // send a request to read an analog pin
    void startADConversion(uint8_t pin_number);
    // reading analog pin value , true if value is valid
    bool readAnalogPin(uint8_t *pinum, uint16_t *value);
    
    void attach(receiveCallbackFunction fnc);
};

// instance of this class (singleton is required to handle an timer interruption.)
extern OTOplug1200ReceiverClass OTOplug1200Receiver;

#endif

