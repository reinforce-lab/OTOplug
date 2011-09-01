//
//  SendingMiscPacketTest.h
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/01/16.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SenTestingKit/SenTestingKit.h"
#import "SWMSocket.h"
#import "SWMConstants.h"
#import "FSKConstants.h"
#import "FSKModem.h"
#import "MockPHY.h"

@interface SendingMiscPacketTest : SenTestCase<SWMSocket> {
	Byte *buf_;
	int bufLength_;
	
	FSKModem *modem_;
	MockPHY *phy_;
}
-(void)testSendingMiscPacket;
@end
