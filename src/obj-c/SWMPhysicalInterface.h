//
//  SMPhysicalInterface.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/28.
//  Copyright 2010 Reinforce Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWMConnecting.h"

@protocol SWMPhysicalInterface

@property(readonly, nonatomic) BOOL isRunning;
@property(retain) id<SWMConnecting> Connector;

-(void) start;
-(void) stop;
- (int)sendPacket:(Byte *)buf length:(int)length;
@end
