//
//  SendingSingleByteTest.m
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/12/01.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "OTORawSocketTests.h"
#import "PWMModem.h"
#import "AudioPHY.h"

@implementation SendingSingleByteTest
#pragma mark - OTOplugDelegate
- (void) readBytesAvailable:(int)length
{
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
            initWithSamplingRate:[modem_ getAudioSamplingRate]
            audioBufferSize:[modem_ getAudioBufferSize]];

    socket_ = [[OTORawSocket alloc] initWithModem:modem_];
    
    AudioPHY *phy = socket_.audioPHY;
    [phy stop];

    socket_.delegate = self;        
    
    phy_.modem = modem_;
    phy_.delegate = socket_;
    
    [phy_ start];
}

-(void)tearDown
{
}
-(void)testSendingSingleByte
{	
	Byte packet[1];
	for(int i =0; i < 256; i++) {
//    for(int i =0; i < 2; i++) {
		// data initialization
		packet[0] = (Byte)i;
		
		// send/receive packet
		[modem_ sendPacket:packet length:1];
		bufLength_ = 0;
		[phy_ transfer:(( 3 +kPWMMaxPacketSize) * 10 * kPWMMark0Samples)];

		[[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
        
		// confirmation
		STAssertEquals(bufLength_, 1, @"Packet length should be 1.");
		STAssertEquals(buf_[0],(uint8_t)i, @"wrong data.");
	}
}

-(void)testSendingLongestPacket
{
	Byte packet[kPWMMaxPacketSize];
	int val = 0;
	for(int c=0; c < 3; c++) {
		// set packet data
		//		int len = kPWMMaxPacketSize;
		int len = kPWMMaxPacketSize ;
		for(int i = 0; i < len; i++) {
			packet[i] = val++;//random();
		}

		// send/receive a packet
		int ret = [modem_ sendPacket:packet length:len];
        STAssertTrue(ret != 0, @"packet send error");
		bufLength_ = 0;
		[phy_ transfer:(( 6 + kPWMMaxPacketSize) * 10 * kPWMMark0Samples)];
        
        [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];

		// confirmation
		STAssertEquals(bufLength_, len, @"Packet length error.");
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
		[phy_ transfer:kPWMModulatorBufferLength];
        
        [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
		
		// confirmation
		STAssertEquals(1, bufLength_,@"Packet length should be 1.");
		STAssertEquals((Byte)i, buf_[0], @"Packet data is not expected one.");
	}
}

@end
