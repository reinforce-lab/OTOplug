//
//  OTOPacketSocket.m
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011 REINFORCE Lab. All rights reserved.
//

#import "OTOPacketSocket.h"
#import "OTOplugDelegate.h"
#import "SWMModem.h"
#import "AudioPHY.h"
#include "math.h"

@interface OTOPacketSocket() {
    uint8_t *sndBuf_;
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
        sndBuf_ = calloc(maxPacketSize_, sizeof(uint8_t));
    }
    return self;
}
-(void)dealloc
{
    free(sndBuf_);
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

#pragma mark - Public methods
-(int)write:(uint8_t *)buf length:(int)length
{
    // exceeding the maximum packet size
    if(length >= maxPacketSize_) return 0; 

    // copy to buffer and calculate the CRC8 checksum
    memcpy(sndBuf_, buf, length * sizeof(uint8_t));  
    sndBuf_[length] = [self calculateCRC8:sndBuf_ length:length];
    
    return [modem_ sendPacket:sndBuf_ length:(length +1)];
}

#pragma mark - AudioPHYDelegate protocol

#pragma mark - SWMSocket protocol
- (void)packetReceived:(uint8_t *)buf length:(int)length
{
    // check CRC8 checksum
    uint8_t crcsum = [self calculateCRC8:buf length:length];
    if(crcsum != 0 || length <= 1) return;
    
    @synchronized(self) {
        if(rcvSize_ == 0) {
            rcvSize_ = length -1; //末尾はCRCチェックサム, 受信長を1減らす。
            memcpy(rcvBuf_, buf, rcvSize_ * sizeof(uint8_t));
        }
    }
    
    // invoke delegate callback
    [self performSelectorOnMainThread:@selector(onReceivePacket) withObject:nil waitUntilDone:NO];
}

@end
