//
//  SWMSocketDelegate.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/28.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>

// Socket interface protocol
@protocol SWMSocket

@required
// Lower layer sends packetReceived message to the upper layer when it receives a packet.
- (void)packetReceived:(Byte *)buf length:(int)length;
// Lower layer sends bufferEmptyCallback message to the upper layer when it completes sending all byte data.
- (void)sendBufferEmptyNotify;

@optional
// Upper layer uses sendPacket message to send a packet.
// It returns number of send bytes. If buffer length is larger than maximum pakcet length, it may return 0 (the buffer may be ignored).
- (int)sendPacket:(Byte *)buf length:(int)length;
@end
