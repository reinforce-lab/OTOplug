//
//  ButtonsViewController.m
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import "ButtonsViewController.h"
#import "PacketTypes.h"

@interface ButtonsViewController () {
    NSArray *buttons_;
    NSArray *labels_;
    Byte buf_[3];
}
@end

@implementation ButtonsViewController
@synthesize numButtons;
@synthesize numLabels;

- (void)viewDidLoad
{
	// 配列に番号順番にインスタンスを設定
    NSMutableArray *buttons = [[NSMutableArray alloc] initWithCapacity:9];
    NSMutableArray *labels  = [[NSMutableArray alloc] initWithCapacity:9];
    for(int i=1; i < 10; i++) {
        [buttons addObject:[self.view viewWithTag:i]];
        [labels  addObject:[self.view viewWithTag:(i +10)]];
    }
    buttons_ = buttons;
    labels_  = labels;
    
    [super viewDidLoad];    
}

- (void)viewDidUnload
{
    [self setNumButtons:nil];
    [self setNumLabels:nil];
    
    [super viewDidUnload];
}

#pragma mark - OTOplugDelegate methods
-(void)sendBufferEmptyNotify
{
    // build packet
    buf_[0] = BUTTONS_PACKET_ID;
    
    Byte b    = 0x00;
    Byte mask = 0x01;
    for(int i=0; i < 8; i++) {
        UIButton *button = (UIButton *)[buttons_ objectAtIndex:i];
        if(button.highlighted) b |= mask;
        mask <<= 1;
    } 
    buf_[1] = b;
    
    b    = 0x00;
    mask = 0x01;
    for(int i=8; i < 9; i++) {
        UIButton *button = (UIButton *)[buttons_ objectAtIndex:i];
        if(button.highlighted) b |= mask;
        mask <<= 1;
    } 
    buf_[2] = b;

    [self.socket write:buf_ length:3];
}
-(void)notifyIsSocketReady:(BOOL)isReady
{
    // Viewを更新, ボタンとラベルを有効化
    for(UIButton *b in buttons_) {
        b.enabled = isReady;
    }
    for(UILabel *l in labels_) {
        l.enabled = isReady;
    }
}
@end
