//
//  MockPHY.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/29.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "MockPHY.h"
#import "PWMConstants.h"
#import "AudioPHYDelegate.h"
#import "SWMModem.h"

@interface MockPHY()
{
    float gain_;
    int audioBufferSize_;
    
    float outputVolume_;
    BOOL isHeadsetIn_;
    BOOL isInterrupted_; 
}

@property(nonatomic, assign, getter = getOutputVolume, setter = setOutputVolume:)   float outputVolume;
@property(nonatomic, assign, getter = getIsHeadsetIn,  setter = setIsHeadsetIn:)    BOOL isHeadsetIn;
@property(nonatomic, assign, getter = getIsInterrpted, setter = setIsInterrupted: ) BOOL isInterrupted;

-(float)getOutputVolume;
-(void)setOutputVolume:(float)outputVolume;
-(BOOL)getIsHeadsetIn;
-(void)setIsHeadsetIn:(BOOL)isHeadsetIn;
-(BOOL)getIsInterrupted;
-(void)setIsInterrupted:(BOOL)isInterrupted;
@end

@implementation MockPHY
@synthesize delegate;
@synthesize modem;
@synthesize gain = gain_;

@dynamic outputVolume;
@dynamic isHeadsetIn;
@dynamic isInterrupted;

-(float)getOutputVolume
{
    return outputVolume_;
}
-(void)setOutputVolume:(float)outputVolume
{
    outputVolume_ = outputVolume;
    [self.modem outputVolumeChanged:outputVolume_];
    [self.delegate outputVolumeChanged:outputVolume_];
}
-(BOOL)getIsHeadsetIn
{
    return isHeadsetIn_;
}
-(void)setIsHeadsetIn:(BOOL)isHeadsetIn
{
    isHeadsetIn_ = isHeadsetIn;
    [self.modem headSetInOutChanged:isHeadsetIn_];
    [self.delegate headSetInOutChanged:isHeadsetIn_];
}
-(BOOL)getIsInterrupted
{
    return isInterrupted_;
}
-(void)setIsInterrupted:(BOOL)isInterrupted
{
    isInterrupted_ = isInterrupted;
    [self.modem audioSessionInterrupted:isInterrupted_];
    [self.delegate audioSessionInterrupted:isInterrupted_];
}

#pragma mark - Constructor
-(id)initWithParameters:(float)samplingRate audioBufferSize:(int)audioBufferSize
{
    self = [super init];
	if(self) {
		gain_ = 1.0;
        audioBufferSize_ = audioBufferSize;
	}
	return self;
}
-(void)dealloc
{
}
-(void) setGain:(float)gain
{
	gain_ = gain;
    self.outputVolume = gain_;
}
-(void)transfer:(int)length {
	int i = 0;
	AudioUnitSampleType *lbuf = calloc(audioBufferSize_,sizeof(AudioUnitSampleType));
    AudioUnitSampleType *rbuf = calloc(audioBufferSize_,sizeof(AudioUnitSampleType));
	for(i=0; i < length;i+=audioBufferSize_) {
        [self.modem modulate:audioBufferSize_ leftBuf:lbuf rightBuf:rbuf];
		for(int k=0; k < audioBufferSize_; k++) {
			lbuf[k] *= gain_;
		}
		[self.modem demodulate:audioBufferSize_ buf:lbuf];
	}
	free(lbuf);
    free(rbuf);
}
-(void) start
{	
    self.isInterrupted = NO;
    self.isHeadsetIn = YES;
    self.outputVolume = gain_;
}
-(void) stop
{
    self.isHeadsetIn = NO;
}
@end
