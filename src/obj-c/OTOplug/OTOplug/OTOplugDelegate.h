//
//  OTOplugDelegate.h
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

@protocol OTOplugDelegate
// bytes are available to be read (user can call read:)
- (void) readBytesAvailable:(int)length;
@end
