//
//  FSKModulator.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab.. All rights reserved.
//
#import <math.h>
#import <strings.h>
#import "FSKConstants.h"
#import "FSKModulator.h"

// Private method declarations
@interface FSKModulator()
@property (nonatomic, assign) BOOL isBufferEmtpy;

-(AudioUnitSampleType *)allocAndInitSineWaveform:(int)length;
-(void)addRawByte:(Byte)value;
-(void)addByte:(Byte)value;
-(void)addBytes:(Byte[])buf length:(int)length;
-(void)addWaveform:(AudioUnitSampleType *)buf length:(int)length;
@end

@implementation FSKModulator
#pragma mark Properties
@synthesize mute = mute_;
@synthesize isBufferEmtpy;

#pragma mark Constuctor
-(id)initWithSocket:(NSObject<SWMSocket> *)socket
{
    self = [super init];
	if(self) {
		resyncRequired_ = TRUE;
		socket_ = [socket retain];
		mark1Cnt_ = 0;
		buf_ = calloc(kFSKModulatorBufferLength, sizeof(AudioUnitSampleType));
		
		// template waveform, '1' , '0', preamble (0xA5)
		mark0Length_ = kFSKMark0Samples;
		mark0_ = [self allocAndInitSineWaveform:mark0Length_];
		mark1Length_ = kFSKMark1Samples;
		mark1_ = [self allocAndInitSineWaveform:mark1Length_];		
	}
	return self;
}
// allocats and initializes packet buffer
-(AudioUnitSampleType *)allocAndInitSineWaveform:(int)length
{
	AudioUnitSampleType *buf = calloc(length, sizeof(AudioUnitSampleType));
	float dw = 2 * M_PI / length;
	for(int i=0; i < length;i++) {
		buf[i] = sin(i * dw) * (1 << kAudioUnitSampleFractionBits);
	}
	return buf;
}
-(void)dealloc
{
	free(mark0_);
	free(mark1_);
	free(buf_);
	
	[socket_ release];
	
	[super dealloc];
}
#pragma mark Private methods
-(void)addWaveform:(AudioUnitSampleType *)buf length:(int)length
{
	memcpy(&buf_[bufWriteIndex_], buf, length * sizeof(AudioUnitSampleType));
	bufWriteIndex_ += length;
}
-(void)addByte:(Byte) value
{
	for(int i=0; i < 8; i++) {
		// LSb-first
		if((value & 0x01) == 0) {
			[self addWaveform:mark0_ length:mark0Length_];
			mark1Cnt_ = 0;
		} else {
			[self addWaveform:mark1_ length:mark1Length_];
			mark1Cnt_++;
			// add a stuffing bit
			if(mark1Cnt_ >= kSWMMaxMark1Length) {
				[self addWaveform:mark0_ length:mark0Length_];
				mark1Cnt_ = 0;
			}
		}
		value >>= 1;
	}
}

-(void)addBytes:(Byte[])buf length:(int)length
{
	for(int i=0; i<length; i++ ) {
		[self addByte:buf[i]];
	}
}
-(void)addRawByte:(Byte) value
{
	for(int i=0; i < 8; i++) {
		// LSb-first
		if((value & 0x01) == 0) {
			[self addWaveform:mark0_ length:mark0Length_];
		} else {
			[self addWaveform:mark1_ length:mark1Length_];
		}
		value >>= 1;
	}
	mark1Cnt_ = 0;
}
#pragma mark Public methods
-(int)sendPacket:(Byte[])buf length:(int)length checksum:(Byte)checksum
{
	@synchronized(self)
	{
		if(mute_) {
			return 0;
		}
		
		// check available buffer length
		int requiredBufferLength = (length + kNumberOfReSyncCode + 1 + 1) * 8 * kFSKMark0Samples; // 3: preamble 1: checksum 1: postamble
		if( (kFSKModulatorBufferLength - bufWriteIndex_) < requiredBufferLength) {
			return 0;
		}
		
		// preamble	
		if(resyncRequired_) {
			resyncRequired_ = FALSE;
			for(int i = 0; i < kNumberOfReSyncCode; i++) {
				[self addRawByte:kSWMSyncCode];
			}
		}

		// write waveform
		[self addBytes:buf length:length];
		[self addByte:checksum];

		// postamble
		[self addRawByte:kSWMSyncCode];
	
		return length;
	}
}
// This method is invoked on audio rendering thread
- (void)modulate:(AudioUnitSampleType [])buf length:(UInt32)length
{
	// fill left channel buffer
	@synchronized(self) {
		BOOL isEmpty = (bufReadIndex_ == bufWriteIndex_);
		if(isEmpty != self.isBufferEmtpy) 
			self.isBufferEmtpy = isEmpty;
		
		if(isEmpty) {
			// waveform buffer is empty
			bzero(buf, sizeof(AudioUnitSampleType) * length);			
		} else {
			// fill buffer tail
			int fill_size = (bufReadIndex_ + kFSKAudioBufferLength) - bufWriteIndex_;
			if(fill_size > 0) {
				bzero(&buf_[bufWriteIndex_] , fill_size * sizeof(AudioUnitSampleType));
				bufWriteIndex_ += fill_size;
				resyncRequired_ = TRUE;
			}
			// copy buffer setment
			memcpy(buf, &buf_[bufReadIndex_], kFSKAudioBufferLength * sizeof(AudioUnitSampleType));
			bufReadIndex_ += kFSKAudioBufferLength;
			// is buffer empty?
			if(bufReadIndex_ == bufWriteIndex_) {
				bufReadIndex_  = 0;
				bufWriteIndex_ = 0;
				[socket_ sendBufferEmptyNotify];
			}
		}
	}
}
@end
