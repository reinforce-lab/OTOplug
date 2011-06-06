//
//  AudioPHY.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab.. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SWMConstants.h"
#import "SWMPhysicalSocket.h"

// Audio physical interface class
@interface AudioPHY : NSObject {
	NSObject<SWMPhysicalSocket> *socket_;
	AudioUnit audioUnit_;
	BOOL isRunning_;
}
@property(nonatomic, readonly, assign) float outputVolume;
@property(nonatomic, readonly, assign) BOOL isHeadsetInOut;
@property(readonly,  nonatomic) BOOL isRunning;

//|length| audio buffer length.
-(id)initWithSocket:(NSObject<SWMPhysicalSocket> *)physicalSocket audioBufferLength:(int)audioBufferLength;
-(void) start;
-(void) stop;
@end
