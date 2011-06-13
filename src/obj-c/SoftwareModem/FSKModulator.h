//
//  FSKModulator.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FSKConstants.h"
#import "SWMSocket.h"

@class FSKModem;
// FSK modulation class
// 1/1200 sinwave
@interface FSKModulator : NSObject {	
	NSObject<SWMSocket> *socket_;
	AudioUnitSampleType *buf_;
	int bufReadIndex_, bufWriteIndex_;
	AudioUnitSampleType *mark0_, *mark1_;
	int mark0Length_, mark1Length_;
	int mark1Cnt_;
	BOOL resyncRequired_;
	BOOL mute_;
}
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, assign, readonly) BOOL isBufferEmtpy;

-(id)initWithSocket:(NSObject<SWMSocket> *)socket;
-(int)sendPacket:(Byte[])buf length:(int)length checksum:(Byte)checksum;
// Modem instance calls this method from audio rendering thread.
- (void)modulate:(AudioUnitSampleType *)buf length:(UInt32)length;
@end
