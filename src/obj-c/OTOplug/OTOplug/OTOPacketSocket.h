//
//  OTOPacketSocket.h
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTORawSocket.h"

// Packet modem. 
// Packet modem. Every packet contains CRC8 at the end of its packet payload.
// A modem rejects a packet which CRC8 does not match.
@interface OTOPacketSocket : OTORawSocket
@end
