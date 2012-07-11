//
//  OTOplugDelegate.h
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011 REINFORCE Lab. All rights reserved.
//

@protocol OTOplugDelegate
@optional
// bytes are available to be read (user can call read:)
-(void)readBytesAvailable:(int)length;
-(void)sendBufferEmptyNotify;

-(void)outputVolumeChanged:(float)volume;
-(void)headSetInOutChanged:(BOOL)isHeadSetIn isMicAvailable:(BOOL)isMicAvailable;
-(void)audioSessionInterrupted:(BOOL)interrupted;
@end
