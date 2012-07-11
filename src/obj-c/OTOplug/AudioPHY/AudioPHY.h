//
//  AudioPHY.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol AudioPHYDelegate, SWMModem;

// Audio physical interface class
@interface AudioPHY : NSObject 

@property(unsafe_unretained, nonatomic) id<AudioPHYDelegate> delegate;
@property(unsafe_unretained, nonatomic) id<SWMModem> modem;

@property(nonatomic, readonly) float outputVolume;
@property(nonatomic, readonly) BOOL  isHeadsetIn;
@property(nonatomic, readonly) BOOL  isMicAvailable;
@property(nonatomic, readonly) BOOL  isInterrupted;

@property(readonly,  nonatomic) BOOL isRunning;

//|length| audio buffer length.
-(id)initWithParameters:(float)samplingRate audioBufferSize:(int)audioBufferSize;
-(void) start;
-(void) stop;
@end
