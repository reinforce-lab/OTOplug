//
//  PWMModulator.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol SWMModem;

@interface PWMModulator : NSObject 

// not KVO compatible
@property (nonatomic, assign, readonly) BOOL isBufferEmtpy;
@property (nonatomic, assign) BOOL mute;

-(id)initWithModem:(id<SWMModem>)modem;
-(int)sendPacket:(Byte[])buf length:(int)length;
// Modem instance calls this method from audio rendering thread.
-(void)modulate:(UInt32)length leftBuf:(AudioUnitSampleType *)leftBuf rightBuf:(AudioUnitSampleType *)rightBuf;
@end
