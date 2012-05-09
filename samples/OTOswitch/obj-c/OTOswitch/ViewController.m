//
//  ViewController.m
//  OTOswitch
//
//  Created by 昭宏 上原 on 12/05/07.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import "ViewController.h"
#import "OTOPacketSocket.h"
#import "PWMModem.h"
//#import "PWMConstants.h"

#define IOPORT_WIDTH 13

@interface ViewController () {
    OTOPacketSocket *socket_;
//    OTORawSocket *socket_;
    int maxPacketSize_;
    Byte *buf_;
    NSTimer *timer_;
    BOOL isPacketReceived_;
    UIImageView *portStatus_[IOPORT_WIDTH];
}
@end

@implementation ViewController
@synthesize connectStatusIcon;
@synthesize portStatusImageViews;
@synthesize connectStatusLabel;

#pragma mark Life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    for(int i=2; i < IOPORT_WIDTH; i++) {
        portStatus_[i] = (UIImageView*)[self.view viewWithTag:i];
    }
    
    // setup modem 
    PWMModem *modem = [[PWMModem alloc] init];
    
    maxPacketSize_ = [modem getMaxPacketSize];    
    buf_ = calloc(maxPacketSize_, sizeof(Byte));
    
    socket_ = [[OTOPacketSocket alloc] initWithModem:modem];
//    socket_ = [[OTORawSocket alloc] initWithModem:modem];
    socket_.delegate = self;
    
    timer_ = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkConnection:) userInfo:nil repeats:YES];
}

- (void)viewDidUnload
{
    [self setConnectStatusIcon:nil];
    [self setConnectStatusLabel:nil];
    [self setPortStatusImageViews:nil];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    free(buf_);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark Private methods
-(void)checkConnection:(NSTimer *)timer
{
    if(isPacketReceived_ != connectStatusIcon.highlighted ) { // update view status
        connectStatusIcon.highlighted = isPacketReceived_;
        connectStatusLabel.text = isPacketReceived_ ? @"Connected" : @"Disconnected";
        double alpha = isPacketReceived_ ? 1.0 : 0.3;
        for(int i=0; i < IOPORT_WIDTH; i++) {
            portStatus_[i].alpha = alpha;
        }        
    }
    isPacketReceived_ = false;
}

#pragma mark OTOplugDelegate
- (void) readBytesAvailable:(int)length
{
    isPacketReceived_ = YES;
    
    [socket_ read:buf_ length:maxPacketSize_];
    

    // dump packet
    NSMutableString *sb = [[NSMutableString alloc] initWithCapacity:100];    
    [sb appendFormat:@"Packet received: %d Packet:", length];
    for(int i = 0; i < length; i++) {
        [sb appendFormat:@"%02X,", buf_[i]];
     }
     NSLog(@"%@", sb);

    // port
    if(length == 2) {
        uint8_t mask = 0x04;
        uint8_t val = buf_[0];
        for(int i=2; i < 8; i++) {
            portStatus_[i].highlighted = ((mask & val) != 0);
            mask <<= 1;
        }
        
        mask = 0x01;
        val = buf_[1];
        for(int i=8; i < 13; i++) {
            portStatus_[i].highlighted = ((mask & val) != 0);
            mask <<= 1;
        }
    }
}

@end
