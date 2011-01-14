//
//  MockPHY.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/29.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SWMConstants.h"
#import "SWMPhysicalSocket.h"
#import "FSKConstants.h"

// Audio physical interface class
@interface MockPHY : NSObject {
	NSObject<SWMPhysicalSocket> *socket_;
	BOOL isRunning_;
	float gain_;
}
@property(readonly,  nonatomic) BOOL isRunning;

-(id)initWithSocket:(NSObject<SWMPhysicalSocket> *)socket;
-(void)transfer:(int)length;
-(void) setGain:(float)gain;
-(void) start;
-(void) stop;
@end
