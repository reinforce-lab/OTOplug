//
//  AudioPHYStatusDelegate.h
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/03.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

// AudioPHY status changed delegate
@protocol AudioPHYDelegate
-(void)outputVolumeChanged:(float)volume;
-(void)headSetInOutChanged:(BOOL)isHeadSetIn;
-(void)audioSessionInterrupted:(BOOL)isInterrupted;
@end
