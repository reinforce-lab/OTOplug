//
//  FSKModem.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FSKConstants.h"
#import "SWMSocket.h"
#import "SWMPhysicalSocket.h"
#import "AudioPHY.h"
#import "FSKDemodulator.h"
#import "FSKModulator.h"

@interface FSKModem : NSObject<SWMSocket, SWMPhysicalSocket> {
 @private	
	NSObject<SWMSocket> *socket_;
	AudioPHY *phy_;
	FSKModulator   *modulator_;
	FSKDemodulator *demodulator_;
	
	NSDate *lastTimePacketReceivedAt_;
	int packetCheckCnt_;
	bool packetReceived_;
}

@property (readonly, nonatomic, getter=getSignalLevel) AudioUnitSampleType signalLevel;
@property (nonatomic) bool packetReceived;

-(id)initWithSocket:(NSObject<SWMSocket> *)socket;
// !CAUTION! This initializer must be used for debug purpose only!
- (id)initWithSocketWithoutPHY:(NSObject<SWMSocket> *)socket;
-(void)start;
-(void)stop;
@end
