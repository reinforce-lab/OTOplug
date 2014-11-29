//
//  PWMModem.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

@import AudioToolbox;
#import "PWMModem.h"
#import "PWMConstants.h"

#import "AudioPHY.h"
#import "PWMDemodulator.h"
#import "PWMModulator.h"

@interface PWMModem ()
{
    id<SWMSocket>   socket_;
	PWMModulator   *modulator_;
	PWMDemodulator *demodulator_;
}
@end

// constant definisitions
@implementation PWMModem
#pragma mark - Constructor
- (id)init
{
    self = [super init];
	if(self) {
		modulator_   = [[PWMModulator alloc] initWithModem:self];
		demodulator_ = [[PWMDemodulator alloc] initWithModem:self];
	}
   return self;
}

#pragma mark - SWMModem protocol
// getting parameter
-(int)getAudioBufferSize
{
    return kPWMAudioBufferSize;
}
-(float)getAudioSamplingRate
{
    return kSWMSamplingRate;
}
-(int)getMaxPacketSize
{
    return kPWMMaxPacketSize;
}

-(void)setSocket:(id<SWMSocket>)socket
{
    socket_ = socket;
}

-(void)demodulate:(UInt32)length buf:(Float32 *)buf
{
    [demodulator_ demodulate:length buf:buf];
}
-(void)modulate:(UInt32)length leftBuf:(Float32 *)leftBuf rightBuf:(Float32 *)rightBuf
{
    [modulator_ modulate:length leftBuf:leftBuf rightBuf:rightBuf];
}

#pragma mark - SWMSocket protocol
-(int)sendPacket:(uint8_t *)buf length:(int)length
{
	return [modulator_ sendPacket:buf length:length];
}
- (void)packetReceived:(uint8_t *)buf length:(int)length
{
    [socket_ packetReceived:buf length:length];
}
- (void)sendBufferEmptyNotify
{
    [socket_ sendBufferEmptyNotify];
}

#pragma mark - AudioPHY delegate
-(void)outputVolumeChanged:(float)volume
{}
-(void)headSetInOutChanged:(BOOL)isHeadSetIn
{
    modulator_.mute = !isHeadSetIn; // turn off modulated signal when plug is out (connected to speaker)
}
-(void)audioSessionInterrupted:(BOOL)isInterrupted
{}
@end
