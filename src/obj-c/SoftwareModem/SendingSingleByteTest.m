//
//  SendingSingleByteTest.m
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/12/01.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SendingSingleByteTest.h"

@implementation SendingSingleByteTest
- (void)packetReceived:(Byte *)buf length:(int)length;
{
	if(buf_ != NULL) {
		free(buf_);
		buf_ = NULL;
	}		
	if(length > 0) {
	   buf_ = calloc(length, sizeof(AudioUnitSampleType));
		memcpy(buf_, buf, length * sizeof(AudioUnitSampleType));
	}
	bufLength_ = length;
}
-(void)sendBufferEmptyNotify
{
}

-(void)setUp
{	
	modem_ = [[FSKModem alloc] initWithSocketWithoutPHY:self];
	phy_ = [[MockPHY alloc] initWithSocket:modem_];
}
-(void)tearDown
{
	[phy_ release];
	[modem_ release];	
}
-(void)testSendingSingleByte
{	
	Byte packet[1];
	for(int i =0; i < 256; i++) {
		// data initialization
		packet[0] = (Byte)i;
		
		// send/receive packet
		[modem_ sendPacket:packet length:1];
		bufLength_ = 0;
		[phy_ transfer:kFSKModulatorBufferLength];
		[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

		// confirmation
		STAssertTrue(buf_ != NULL, @"receive buffer must not be nil.");
		STAssertEquals(1, bufLength_,@"Packet length should be 1.");
		STAssertEquals((Byte)i, buf_[0], @"Packet data is not expected one.");
	}
}
-(void)testSendingLongestPacket
{
	Byte packet[kFSKMaxPacketLength];
	int val = 0;
	for(int c=0; c < 3; c++) {
		// set packet data
		//		int len = kFSKMaxPacketLength;
		int len = kFSKMaxPacketLength ;
		for(int i = 0; i < len; i++) {
			packet[i] = val++;//random();
		}

		// send/receive a packet
		int ret = [modem_ sendPacket:packet length:len];		
		STAssertNotEquals(ret, 0, @"packet send error");
		bufLength_ = 0;
		[phy_ transfer:(2 * kFSKModulatorBufferLength)];
		[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];

		// confirmation
		STAssertTrue(buf_ != NULL, @"receive buffer must not be nil.");
		STAssertEquals(len , bufLength_,@"Packet length error.");
		for (int i=0; i < len ; i++) {
			STAssertEquals(packet[i], buf_[i], @"Packet data is not expected one.");
		}
	}	
}
-(void)testInsensitiveToSignalPolarity
{
	[phy_ setGain:-1.0];
	Byte packet[1];
	for(int i =0; i < 256; i++) {
		// data initialization
		packet[0] = (Byte)i;
		
		// send/receive packet
		[modem_ sendPacket:packet length:1];
		bufLength_ = 0;
		[phy_ transfer:kFSKModulatorBufferLength];
		[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		
		// confirmation
		STAssertTrue(buf_ != NULL, @"receive buffer must not be nil.");
		STAssertEquals(1, bufLength_,@"Packet length should be 1.");
		STAssertEquals((Byte)i, buf_[0], @"Packet data is not expected one.");
	}
}
@end
