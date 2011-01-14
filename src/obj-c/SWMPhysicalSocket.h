//
//  SWMPhysicalSocket.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/28.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@protocol SWMPhysicalSocket
-(void)demodulate:(AudioUnitSampleType *)buf length:(int)length;
-(void)modulate:(AudioUnitSampleType *)buf length:(UInt32)length;
@end
