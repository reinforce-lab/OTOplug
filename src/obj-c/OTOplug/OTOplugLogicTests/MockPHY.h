//
//  MockPHY.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/29.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AudioToolbox;

@protocol AudioPHYDelegate, SWMModem;

// Audio physical interface class
@interface MockPHY : NSObject

@property(weak, nonatomic) id<AudioPHYDelegate> delegate;
@property(weak, nonatomic) id<SWMModem> modem;
@property(nonatomic, assign) float gain;

@property(nonatomic, readonly) float outputVolume;
@property(nonatomic, readonly) BOOL isHeadsetIn;
@property(nonatomic, readonly) BOOL isInterrupted;

//|length| audio buffer length.
-(id)initWithParameters:(float)samplingRate audioBufferSize:(int)audioBufferSize;
-(void) start;
-(void) stop;

-(void)transfer:(int)length;
@end
