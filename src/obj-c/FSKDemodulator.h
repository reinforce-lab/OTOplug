//
//  FSKDemodulator.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/25.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SWMSocket.h"
#import "FSKConstants.h"

enum FSKByteReceiverState { Start = 0, BitReceiving, StuffingBit };

@interface FSKDemodulator : NSObject {
	NSObject<SWMSocket> *socket_;
	
	AudioUnitSampleType lpfSig_, sliceLevel_;
	BOOL isSignHigh_, lostCarrier_, isPreviousPulseNarrow_;
	int clockPhase_, pllPhase_;
	enum FSKByteReceiverState rcvState_;
	u_int16_t rcvShiftReg_;
	int rcvBitLength_, rcvMark1Count_;
	Byte *rcvBuf_;
	int rcvBufLength_;
	AudioUnitSampleType signalLevel_;
}
// Average signal amplitude in an unit of AudioUnitSampleType.
@property AudioUnitSampleType signalLevel;
-(id)initWithSocket:(NSObject<SWMSocket> *)socket;
-(void)demodulate:(AudioUnitSampleType *)buf length:(int)length;
@end
