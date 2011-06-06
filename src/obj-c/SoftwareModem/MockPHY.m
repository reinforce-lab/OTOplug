//
//  MockPHY.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/29.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "MockPHY.h"

@implementation MockPHY
@synthesize isRunning;

-(id)initWithSocket:(NSObject<SWMPhysicalSocket> *)socket
{
    self = [super init];
	if(self) {
		socket_ = [socket retain];
		gain_ = 1.0;
	}
	return self;
}
-(void)dealloc
{
	[socket_ release];
	[super dealloc];
}
-(void) setGain:(float)gain
{
	gain_ = gain;
}
-(void)transfer:(int)length {
	int i = 0;
	AudioUnitSampleType *buf = calloc(kFSKAudioBufferLength,sizeof(AudioUnitSampleType));
	for(i=0; i < length;i+=kFSKAudioBufferLength) {
		[socket_ modulate:buf   length:kFSKAudioBufferLength];
		for(int k=0; k < kFSKAudioBufferLength; k++) {
			buf[k] *= gain_;
		}
		[socket_ demodulate:buf length:kFSKAudioBufferLength];
	}
	free(buf);
}
-(void) start
{	
}
-(void) stop
{
}
@end
