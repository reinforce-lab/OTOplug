//
//  SlideBarsViewController.m
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import "SlideBarsViewController.h"
#import "PacketTypes.h"

@interface SlideBarsViewController () {
    Byte buf_[5];
    NSArray *slides_;
    NSArray *labels_;
}
@end

@implementation SlideBarsViewController
@synthesize slideBars;
@synthesize slideLabels;

#pragma mark - Life cycle
- (void)viewDidLoad
{    
    NSMutableArray *slides  = [[NSMutableArray alloc] initWithCapacity:4];
    NSMutableArray *labels  = [[NSMutableArray alloc] initWithCapacity:4];
    for(int i=1; i < 5; i++) {
        UISlider *s= (UISlider *)[self.view viewWithTag:(i +10)];        
//NSLog(@"s %@", s);
        [s addTarget:self action:@selector(slideValueChanged:) forControlEvents:UIControlEventValueChanged];
        [slides addObject:s];
        [labels addObject:[self.view viewWithTag:(i +20)]];
    }
    slides_  = slides;
    labels_  = labels;
    
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setSlideBars:nil];
    [self setSlideLabels:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}
#pragma mark - OTOplugDelegate methods
-(void)sendBufferEmptyNotify
{
    buf_[0] = SLIDEBAR_PACKET_ID;
    for(int i=0; i < 4; i++) {
        UISlider *s = (UISlider *)[slides_ objectAtIndex:i];
        buf_[i +1] = (Byte)s.value;
    }
    
    [self.socket write:buf_ length:5];
}

#pragma mark - Protected methods
-(void)notifyIsSocketReady:(BOOL)isReady 
{
    float a = isReady ? 1.0 : 0.5;
    
    for(UIView *v in slides_) {
        v.alpha = a;
        v.userInteractionEnabled = isReady;
    }
    for(UIView *v in labels_) {
        v.alpha = a;
    }
}
#pragma mark - Private method
- (IBAction)slideValueChanged:(id)sender {
    UISlider *s = (UISlider *)sender;
    UILabel  *l = (UILabel *)[self.view viewWithTag:(s.tag + 10)];
    l.text = [NSString stringWithFormat:@"%d", (int)s.value];
}
@end
