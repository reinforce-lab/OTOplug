//
//  SendingMiscPacketTest.m
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/01/16.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SendingMiscPacketTest.h"
#import "PWMModem.h"

#import "AudioPHY.h"

@implementation SendingMiscPacketTest
#pragma mark - OTOplugDelegate
- (void) readBytesAvailable:(int)length
{
    NSLog(@"%s is called", __func__);
   bufLength_ = [socket_ read:buf_ length:[modem_ getMaxPacketSize]];    
}		

-(void)sendBufferEmptyNotify
{
}

-(void)setUp
{
	modem_ = [PWMModem new];
    
    buf_ = calloc([modem_ getMaxPacketSize], sizeof(uint8_t));
    bufLength_ = 0;
    
    phy_ = [[MockPHY alloc] 
            initWithParameters:[modem_ getAudioSamplingRate]
            audioBufferSize:[modem_ getAudioBufferSize]];
    socket_ = [[OTORawSocket alloc] initWithModem:modem_];
    
    AudioPHY *phy = socket_.audioPHY;
    [phy stop];

    phy_.modem = modem_;
    phy_.delegate = socket_;
    
    [phy_ start];
}
-(void)tearDown
{
}
-(void)testSendingMiscPacket
{	
	int length = 10;
	Byte packet[10];
	for(int i=0; i < length;i++) {
		packet[i] = 0;
	}
	// send/receive packet
    bufLength_ = 0;
    [socket_ write:packet length:length];
	[phy_ transfer:kPWMModulatorBufferLength];

    // read
//	[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];	    
    
	// confirmation
	STAssertEquals(length, bufLength_,@"Packet length should be 10.");
	for(int i=0; i < length; i++) {
		STAssertEquals(packet[i], buf_[i],[NSString stringWithFormat:@"Packet %dth data is not expected one.", i]);		
	}
}
@end
