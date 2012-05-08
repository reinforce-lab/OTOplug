//
//  OTOplugTestClientViewController.m
//  OTOplugTransmitterTestClient
//
//  Created by 上原 昭宏 on 11/06/03.
//  Copyright 2011 REINFORCE Lab. All rights reserved.
//

#import "TestClientViewController.h"

#import "ctype.h"
#import "OTOPacketSocket.h"
#import "PWMModem.h"
#import "AudioPHY.h"

@interface TestClientViewController() {
    OTOPacketSocket *socket_;
    PWMModem *modem_;
    NSMutableString *logText_;
    uint8_t *buf_;
}

-(void)updateConnectionStateLabel;
-(void)dumpPacket:(Byte *)buf length:(int)length;
-(void)clearTextView;
@end

@implementation TestClientViewController
#pragma mark - Properties

#pragma mark - Constructor
- (void)dealloc
{
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	logText_ = [NSMutableString stringWithCapacity:1000];
    textView_.text = @"";

	modem_ = [[PWMModem alloc] init];
    
    buf_ = calloc([modem_ getMaxPacketSize], sizeof(uint8_t));
    
    socket_ = [[OTOPacketSocket alloc] initWithModem:modem_];
    socket_.delegate = self;

    [socket_.audioPHY addObserver:self forKeyPath:@"isHeadsetIn" options:NSKeyValueObservingOptionNew context:nil];

	[self updateConnectionStateLabel]; 	
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [socket_.audioPHY removeObserver:self forKeyPath:@"isHeadsetIn"];	
    free(buf_);
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Event handler
-(IBAction)clearButtonTouchUpInside:(id)sender
{
	[self clearTextView];
}
#pragma mark - Private methods
-(void)updateConnectionStateLabel
{
    AudioPHY *phy = socket_.audioPHY;
//    BOOL isss = [phy getIsHeadesetIn];
    NSLog(@"%d", phy.isHeadsetIn);
	statusLabelView_.text = socket_.audioPHY.isHeadsetIn ? @"Connected" : @"Not connected";
}
-(void)clearTextView
{
	logText_ = [NSMutableString stringWithCapacity:1000];
	textView_.text = logText_;
}
-(void)dumpPacket:(Byte *)buf length:(int)length
{
	NSMutableString *lineText = [NSMutableString stringWithCapacity:(length *4)];
	for(int i = 0; i < length -1; i++) {
		if(isascii( buf[i])) {
			[lineText appendFormat:@"%c", buf[i]];
		} else {
			[lineText appendFormat:@"% (0x%02X) ", buf[i]];
		}
	}
	[logText_ appendString:lineText];
	textView_.text = logText_;
}

#pragma mark - OTOplugDelegate
- (void) readBytesAvailable:(int)length
{
    [socket_ read:buf_ length:length];
	[self dumpPacket:buf_ length:length]; 
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == socket_.audioPHY) {
       	// isHeadsetIn is changed
		[self updateConnectionStateLabel];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Public methods
@end
