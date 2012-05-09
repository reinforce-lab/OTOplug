//
//  OTOPacketSocket.m
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011 REINFORCE Lab.. All rights reserved.
//

#import "OTOPacketSocket.h"
#import "OTOplugDelegate.h"
#import "SWMModem.h"
#import "AudioPHY.h"
#include "math.h"

@interface OTOPacketSocket()
{
}
-(uint8_t)calculateCRC8:(uint8_t [])buf length:(int)length;
@end

uint8_t crc_ibutton_update(uint8_t crc, uint8_t data);


@implementation OTOPacketSocket

#pragma mark - Constructor
// initializer
-(id)initWithModem:(id<SWMModem>)_modem
{
    self = [super initWithModem:_modem];
    if(self) {
    }
    return self;
}
-(void)dealloc
{
}

#pragma mark - Private methods
uint8_t crc_ibutton_update(uint8_t crc, uint8_t data)
{
	uint8_t i;
	crc = (uint8_t)(crc ^ data);
	for (i = 0; i < 8; i++)
	{
		if ((crc & 0x01) != 0)
			crc = (uint8_t)((crc >> 1) ^ 0x8c);
		else
			crc >>= 1;
	}
	return crc;
}
-(uint8_t)calculateCRC8:(uint8_t [])buf length:(int)length
{
	uint8_t cc = 0;
	for(int i=0; i < length;i++) {
		cc = crc_ibutton_update(cc, buf[i]);
	}
	return cc;
}
#pragma mark - Private methods
-(void)onReceivePacket
{
    [self.delegate readBytesAvailable:(rcvSize_ -1)];
}

#pragma mark - Public methods

#pragma mark - AudioPHYDelegate protocol

#pragma mark - SWMSocket protocol
- (void)packetReceived:(uint8_t *)buf length:(int)length
{
    @synchronized(self) {
        if(rcvSize_ == 0) {
            rcvSize_ = length;
            memcpy(rcvBuf_, buf, length * sizeof(uint8_t));

            // check CRC8 checksum
            uint8_t crcsum = [self calculateCRC8:rcvBuf_ length:length];            
            
            if(crcsum == 0 && rcvSize_ > 0) {
                [self performSelectorOnMainThread:@selector(onReceivePacket) withObject:nil waitUntilDone:NO];
            }
        }
    }
}
- (void)sendBufferEmptyNotify
{
}
@end
