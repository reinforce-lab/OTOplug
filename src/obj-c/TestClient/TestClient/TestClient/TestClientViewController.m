//
//  OTOplugTestClientViewController.m
//  OTOplugTransmitterTestClient
//
//  Created by 上原 昭宏 on 11/06/03.
//  Copyright 2011 REINFORCE Lab. All rights reserved.
//

#import "TestClientViewController.h"

#import "ctype.h"
#import "FSKModem.h"
#import "SWMSocket.h"

@interface TestClientViewController()
@property (nonatomic, retain) FSKModem *modem;
@property (nonatomic, retain) NSMutableString *logText;

-(void)updateConnectionStateLabel;
-(void)dumpPacket:(Byte *)buf length:(int)length;
-(void)clearTextView;
@end

@implementation TestClientViewController
#pragma mark - Properties
@synthesize modem;
@synthesize logText;

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
	self.logText = [NSMutableString stringWithCapacity:1000];

	self.modem = [[FSKModem alloc] initWithSocket:self];
	[self.modem addObserver:self forKeyPath:@"isHeadsetInOut" options:NSKeyValueObservingOptionNew context:(__bridge void*)modem];
	self.modem.mute = YES;
	[self updateConnectionStateLabel];
	[self.modem start];
	
    [super viewDidLoad];
}

- (void)viewDidUnload
{
	[self.modem stop];
	[self.modem removeObserver:self forKeyPath:@"isHeadsetInOut"];	
	self.modem = nil;
	self.logText = nil;
	
    [super viewDidUnload];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - SWMSocket
- (void)packetReceived:(Byte *)buf length:(int)length
{
	[self dumpPacket:buf length:length];
}
- (void)sendBufferEmptyNotify
{
}
#pragma mark - Event handler
-(IBAction)clearButtonTouchUpInside:(id)sender
{
	[self clearTextView];
}
#pragma mark - Private methods
-(void)updateConnectionStateLabel
{
//	statusLabelView_.text =self.modem.isHeadsetInOut ? @"Connected" : @"Not connected";
}
-(void)clearTextView
{
	self.logText = [NSMutableString stringWithCapacity:1000];
	textView_.text = self.logText;
}
-(void)dumpPacket:(Byte *)buf length:(int)length
{
	NSMutableString *lineText = [NSMutableString stringWithCapacity:(length *4)];
	for(int i = 0; i < length; i++) {
		if(isascii( buf[i])) {
			[lineText appendFormat:@"%c", buf[i]];
		} else {
			[lineText appendFormat:@"% 0x%02X ", buf[i]];
		}
	}
	[self.logText appendString:lineText];
	textView_.text = self.logText;
}
#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ((__bridge FSKModem *)context == self.modem) {
       	// isHeadsetInOut
		[self updateConnectionStateLabel];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
#pragma mark - Public methods
@end
