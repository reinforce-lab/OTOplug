//
//  SWMModem.h
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011  __MyCompanyName__. All rights reserved.
//
@import AudioToolbox;
#import "SWMSocket.h"
#import "AudioPHYDelegate.h"

// AudioPHY to Softwaremodem connection delegate
// AudioPHY is passed a modem asa delegate.
// 
// +---------------+
// | id<SWMSocket> |
// +---------------+
//   | 
//   | initWithSocket
//   | sendPacket
//   *
// +----------------+
// | Modem          |
// +----------------+
//   ^          
//   | modulate
//   | demodulate
//   | statusChanges
//   |
// +----------------+
// | Audio PHY      |
// +----------------+
//

@protocol SWMModem <AudioPHYDelegate, SWMSocket>
// getting parameter
-(int)getAudioBufferSize;
-(float)getAudioSamplingRate;
-(int)getMaxPacketSize;

-(void)setSocket:(id<SWMSocket>)socket;

// interface to AudioPHY
-(void)demodulate:(UInt32)length buf:(Float32 *)buf;
-(void)modulate:(UInt32)length leftBuf:(Float32 *)leftBuf rightBuf:(Float32 *)rightBuf;
@end
