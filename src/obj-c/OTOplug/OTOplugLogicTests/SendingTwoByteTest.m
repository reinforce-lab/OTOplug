//
//  SendingTwoByteTest.m
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/01/09.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SendingTwoByteTest.h"

@implementation SendingTwoByteTest

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
	modem_ = [[PWMModem alloc] initWithSocketWithoutPHY:self];
	phy_ = [[MockPHY alloc] initWithSocket:modem_];
}
-(void)tearDown
{
}
-(void)testSendingTwoByte
{	
	Byte packet[2];
	for(int x=0; x < 256; x++) {
	for(int y =0; y < 256; y++) {
		// data initialization
		packet[0] = (Byte)x;
		packet[1] = (Byte)y;
		
		// send/receive packet
		[modem_ sendPacket:packet length:2];
		bufLength_ = 0;
		[phy_ transfer:kPWMModulatorBufferLength];
		[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		
		// confirmation
		STAssertTrue(buf_ != NULL, @"receive buffer must not be nil.");
		STAssertEquals(2, bufLength_,@"Packet length should be 1.");
		STAssertEquals((Byte)x, buf_[0], @"Packet data0 is not expected one.");
		STAssertEquals((Byte)y, buf_[1], @"Packet data1 is not expected one.");
	}
	}
}
	
@end
