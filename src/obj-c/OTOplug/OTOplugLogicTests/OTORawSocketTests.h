//
//  SendingSingleByteTest.h
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/12/01.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SenTestingKit/SenTestingKit.h"
#import "SWMSocket.h"
#import "PWMConstants.h"
#import "PWMModem.h"
#import "OTORawSocket.h"
#import "MockPHY.h"

@interface SendingSingleByteTest : SenTestCase<OTOplugDelegate> {
	Byte *buf_;
	int bufLength_;
	
    OTORawSocket *socket_;
	PWMModem *modem_;
	MockPHY *phy_;
}

-(void)testSendingSingleByte;
-(void)testSendingLongestPacket;
-(void)testInsensitiveToSignalPolarity;
@end
