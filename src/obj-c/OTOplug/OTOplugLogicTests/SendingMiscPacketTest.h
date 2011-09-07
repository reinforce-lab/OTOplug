//
//  SendingMiscPacketTest.h
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/01/16.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SenTestingKit/SenTestingKit.h"
#import "SWMSocket.h"
#import "PWMConstants.h"
#import "PWMModem.h"
#import "OTORawSocket.h"
#import "MockPHY.h"

@interface SendingMiscPacketTest : SenTestCase<OTOplugDelegate> {
	Byte *buf_;
	int bufLength_;
	
    OTORawSocket *socket_;
	PWMModem *modem_;
	MockPHY *phy_;
}
-(void)testSendingMiscPacket;
@end
