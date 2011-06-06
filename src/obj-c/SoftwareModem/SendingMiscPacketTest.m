//
//  SendingMiscPacketTest.m
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/01/16.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SendingMiscPacketTest.h"

@implementation SendingMiscPacketTest

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
-(void)testSendingMiscPacket
{	
	int length = 10;
	Byte packet[10];
	for(int i=0; i < length;i++) {
		packet[i] = 0;
	}
	// send/receive packet
	[modem_ sendPacket:packet length:length];
	bufLength_ = 0;
	[phy_ transfer:kFSKModulatorBufferLength];
	[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	
	// confirmation
	STAssertTrue(buf_ != NULL, @"receive buffer must not be nil.");
	STAssertEquals(length, bufLength_,@"Packet length should be 1.");
	for(int i=0; i < length; i++) {
		STAssertEquals(packet[i], buf_[i],[NSString stringWithFormat:@"Packet %dth data is not expected one.", i]);		
	}
}
@end
