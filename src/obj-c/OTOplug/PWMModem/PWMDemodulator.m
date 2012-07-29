//
//  PWMDemodulator.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/25.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "PWMDemodulator.h"
#import "PWMConstants.h"
#import "SWMModem.h"

enum PWMByteReceiverState { Start = 0, BitReceiving, StuffingBit };

@interface PWMDemodulator () 
{	
	AudioUnitSampleType lpfSig_, sliceLevel_;
	BOOL isSignHigh_, lostCarrier_, isPreviousPulseNarrow_;
	int clockPhase_, pllPhase_;
	enum PWMByteReceiverState rcvState_;
	u_int16_t rcvShiftReg_;
	int rcvBitLength_, rcvMark1Count_;
	uint8_t *rcvBuf_;
	int rcvBufLength_;
	AudioUnitSampleType signalLevel_;

    __unsafe_unretained id<SWMModem> modem_;
}

-(void)receiveBit:(BOOL)value;
-(void)lostCarrier;
@end

@implementation PWMDemodulator
#pragma mark Properties
@synthesize signalLevel = signalLevel_;

#pragma mark Constructor
-(id)initWithModem:(id<SWMModem>)m
{
    self= [super init];
	if(self) {
		sliceLevel_ = kPWMSliceLevel;
		modem_ = m;
		rcvBuf_   = malloc(kPWMMaxPacketSize);
	}
	return self;
}
-(void)dealloc
{
	free(rcvBuf_);
}
#pragma mark Private methods
-(void)receiveBit:(BOOL)value
{	
	// bit shifter
	rcvShiftReg_ >>= 1;	
	rcvBitLength_++;
	if(value) {
		rcvShiftReg_ |= 0x8000;
		rcvMark1Count_++;
	} else {
		rcvMark1Count_ = 0;
	}

//NSLog(@"RB:%d ST:%d BLEN:%d SREG:%x", value, rcvState_, rcvBitLength_, rcvShiftReg_);
	
	// state machine
	switch (rcvState_) {
		case Start:
			if(rcvBitLength_ >= 8 && (Byte)(rcvShiftReg_ >> 8) == kSWMSyncCode) {
				rcvState_ = BitReceiving;
				rcvBitLength_ = 0;
//NSLog(@"             Start->BitReceiving");
			}
			break;
		case BitReceiving:
			if(rcvBitLength_ >= 8) {
				rcvBitLength_ = 0;
				// receive byte data
				rcvBuf_[rcvBufLength_++] = (Byte)(rcvShiftReg_ >> 8);
				if(rcvBufLength_ >= kPWMMaxPacketSize) {
					// buffer overflow, send EOP
					[modem_ packetReceived:rcvBuf_ length:rcvBufLength_];
					rcvBufLength_ = 0;
				}
//NSLog(@"             ByteReceived:0x%02X",(Byte)(rcvShiftReg_ >>8) );
			}
			if(rcvMark1Count_ >= kSWMMaxMark1Length) {
				rcvState_ = StuffingBit;
//NSLog(@"             BitReceiving->StuffingBit");
			}
			break;
		case StuffingBit:
			if(value) {
				// End of packet
				rcvState_ = Start;
				if(rcvBufLength_ > 0) {
//NSLog(@"Packet: length:%d", rcvBufLength_ );
					[modem_ packetReceived:rcvBuf_ length:rcvBufLength_];
					rcvBufLength_ = 0;
				}				
//NSLog(@"            StuffingBit->Start");
			} else {
				rcvState_ = BitReceiving;
				rcvShiftReg_ <<= 1;
				rcvBitLength_ --;
//NSLog(@"            StuffingBit->BitReceiving");
			}
			break;
		default:
			rcvState_ = Start;
			break;
	}
}
-(void)lostCarrier
{
	if(rcvBufLength_ > 0) {
		[modem_ packetReceived:rcvBuf_ length:rcvBufLength_];
		rcvBufLength_ = 0;
	}
}
#pragma mark Public methods
-(void)demodulate:(UInt32)length buf:(AudioUnitSampleType *)buf
{	
	assert(kPWMAudioBufferSize == length);
	
	AudioUnitSampleType sigLevel = self.signalLevel;
	for(int i=0; i < length;i++) {
		// Low-pass filter
 		AudioUnitSampleType sig = buf[i];
		lpfSig_ += (sig - lpfSig_) / 512 ; // LPF time constant 44.1kHz/512 =86Hz
		AudioUnitSampleType diff = sig - lpfSig_;

		// Signal level
		sigLevel += (abs(diff) - sigLevel) / (4*1024); // LPF time constant 44.1kHz/(4*1024) = 11Hz
		
		// edge detection
		BOOL edgeDetection = false;
		if(isSignHigh_) {
			if(diff < -1 * sliceLevel_) {
				edgeDetection = true;
				isSignHigh_ = false;
			} 
		} else {
			if(diff > sliceLevel_) {
				edgeDetection = true;
				isSignHigh_ = true;
			} 
		}

//NSLog(@"AMP:%ld", diff);
		// bit decoding
		if(edgeDetection) {
			BOOL isNarrowPulse = (clockPhase_ <= (kPWMPulseWidthThreashold /2));
			
			lostCarrier_ = FALSE;
			clockPhase_ = 0;
			pllPhase_++;
			
			if(pllPhase_ >= 2) {
				if(isPreviousPulseNarrow_ && isNarrowPulse) {
					// set mark1
//NSLog(@"mark1:%d", clockPhase_);
					pllPhase_ = 0;
					[self receiveBit:TRUE];
				} else if(!isPreviousPulseNarrow_ && !isNarrowPulse) {					
					// set mark0
//NSLog(@"mark0:%d", clockPhase_);
					pllPhase_ = 0;
					[self receiveBit:FALSE];
				} else {
//NSLog(@"wrong bit detection. isPreviousPulseNarrow:%d isNarrowPulse:%d", isPreviousPulseNarrow_, isNarrowPulse);
				}

			}
			isPreviousPulseNarrow_ = isNarrowPulse;
		}
		clockPhase_++;
		
		// lost carrier?
		if(clockPhase_ == kPWMLostCarrierDuration) {
			lostCarrier_ = TRUE;
			[self lostCarrier];
		}
	}
	self.signalLevel = sigLevel;
}

@end
