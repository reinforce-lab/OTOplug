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
}
@property (nonatomic, retain, readonly) AudioPHY *audioPHY;
@property (nonatomic, retain, readonly) FSKModulator *modulator;

@property (nonatomic, nonatomic, readonly, getter=getSignalLevel) AudioUnitSampleType signalLevel;
@property (nonatomic, getter=getMute, setter=setMute:) BOOL mute;

-(id)initWithSocket:(NSObject<SWMSocket> *)socket;
// !CAUTION! This initializer must be used for debug purpose only!
- (id)initWithSocketWithoutPHY:(NSObject<SWMSocket> *)socket;
-(void)start;
-(void)stop;
@end
