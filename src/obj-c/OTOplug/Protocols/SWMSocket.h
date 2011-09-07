//
//  SWMSocketDelegate.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/28.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

// Softwaremodem internal-connection socket
// 
// 
// +----------------+
// | Upper layer    |
// +----------------+
//   |           ^
//   |sendPacket |
//   |           |packetReceived
//   |           |sendBufferEmptyNotify
//   *           |
// +----------------+
// | Lower layer    |
// +----------------+
//
@protocol SWMSocket

@required
// Lower layer sends packetReceived message to the upper layer when it receives a packet.
- (void)packetReceived:(uint8_t *)buf length:(int)length;
// Lower layer sends bufferEmptyCallback message to the upper layer while its send buffer is empy.
// Period of this message is called is depends on lower layer implementation.
- (void)sendBufferEmptyNotify;

@optional
// Upper layer sends sendPacket message to send a packet.
// It returns number of sent bytes. 
// If buffer length is larger than maximum pakcet length, it may return 0 (the buffer may be ignored).
- (int)sendPacket:(uint8_t *)buf length:(int)length;
@end
