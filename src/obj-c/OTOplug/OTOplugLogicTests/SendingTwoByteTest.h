//
//  SendingSingleByteTest.h
//  SoundModemTestCases
//
//  Created by UEHARA AKIHIRO on 10/01/09.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

#import "SenTestingKit/SenTestingKit.h"
#import "SWMSocket.h"
#import "SWMConstants.h"
#import "PWMConstants.h"
#import "PWMModem.h"
#import "MockPHY.h"

@interface SendingTwoByteTest : SenTestCase<SWMSocket> {
	Byte *buf_;
	int bufLength_;
	
	PWMModem *modem_;
	MockPHY *phy_;
}
-(void)testSendingTwoByte;
@end
