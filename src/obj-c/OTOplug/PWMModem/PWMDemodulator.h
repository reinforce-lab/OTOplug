//
//  PWMDemodulator.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/25.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AudioToolbox;

@protocol SWMModem;

@interface PWMDemodulator : NSObject
// Average signal amplitude in an unit of Float32.
@property Float32 signalLevel;

-(id)initWithModem:(id<SWMModem>)mdoem;
-(void)demodulate:(UInt32)length buf:(Float32 *)buf;
@end
