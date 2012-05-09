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

@interface ViewController () {
    OTORawSocket *socket_;
    int maxPacketSize_;
    Byte *buf_;
    NSTimer *timer_;
    BOOL isPacketReceived_;
    UIImageView *portStatus_[4];
}

- (uint8_t) decodePacketOctet:(uint8_t)data;
@end

@implementation ViewController
@synthesize idTextLabel;
@synthesize connectStatusIcon;
@synthesize portStatusImageViews;
@synthesize connectStatusLabel;

#pragma mark Life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    for(int i=1; i <= 4; i++) {
        portStatus_[i -1] = (UIImageView*)[self.view viewWithTag:i];
    }
    
    // setup modem 
    PWMModem *modem = [[PWMModem alloc] init];
    
    maxPacketSize_ = [modem getMaxPacketSize];    
    buf_ = calloc(maxPacketSize_, sizeof(Byte));
    
    socket_ = [[OTORawSocket alloc] initWithModem:modem];
    socket_.delegate = self;
    
    timer_ = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(checkConnection:) userInfo:nil repeats:YES];
}

- (void)viewDidUnload
{
    [self setConnectStatusIcon:nil];
    [self setConnectStatusLabel:nil];
    [self setPortStatusImageViews:nil];
    [self setIdTextLabel:nil];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    free(buf_);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Private methods
-(void)checkConnection:(NSTimer *)timer
{
    if(isPacketReceived_ != connectStatusIcon.highlighted ) { // update view status
        connectStatusIcon.highlighted = isPacketReceived_;
        connectStatusLabel.text = isPacketReceived_ ? @"Connected" : @"Disconnected";
        double alpha = isPacketReceived_ ? 1.0 : 0.3;
        for(int i=0; i < 4; i++) {
            portStatus_[i].alpha = alpha;
        }        
    }
    isPacketReceived_ = false;
}

-(uint8_t) decodePacketOctet:(uint8_t) data
{
    uint8_t mask = 0x03;
    uint8_t bitp = 0x08;
    uint8_t b = 0;
    
    for(int i=0; i < 4; i++) {
        uint8_t b2 = (data & mask) >> ( i * 2);
        if(b2 == 0x00 || b2 == 0x03) {
            return 0xff; // bit error               
        }
        
        if((b2 & 0x02) != 0) {
            b |= bitp;   
        }
        
        mask <<= 2;
        bitp >>= 1;
    }

    return  b;
}

#pragma mark OTOplugDelegate
- (void) readBytesAvailable:(int)length
{
    isPacketReceived_ = YES;
    
    [socket_ read:buf_ length:maxPacketSize_];    

    // raw packet dump
    /*
    NSMutableString *sb = [[NSMutableString alloc] initWithCapacity:100];    
    [sb appendFormat:@"Packet received: %d Packet:", length];
    for(int i = 0; i < length; i++) {
        [sb appendFormat:@"%02X,", buf_[i]];
     }
     NSLog(@"%@", sb);*/
    
    // decoded packet dump
    /*
    sb = [[NSMutableString alloc] initWithCapacity:100];    
    for(int i = 0; i < length; i++) {
        [sb appendFormat:@"%02X,", [self decodePacketOctet:buf_[i]]];
    }
    NSLog(@"%@", sb);*/

    if(length == 3) {
        uint8_t id0 = [self decodePacketOctet:buf_[0]];
        uint8_t id1 = [self decodePacketOctet:buf_[1]];
        idTextLabel.text = [NSString stringWithFormat:@"%02X", (id1 << 4 | id0)];
        
        uint8_t portb = [self decodePacketOctet:buf_[2]];
        for(int i=0; i < 4; i++) {
            portStatus_[i].highlighted = ((portb & (0x01 << i)) != 0);
        }
    }
}

@end
