//
//  jackViewController.m
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import "jackViewController.h"
#import "AppDelegate.h"
#import "AudioPHY.h"

@interface jackViewController ()
-(void)showWarningDialog;
-(BOOL)isHeadsetReady;
-(void)updateJackVCViews;
-(void)updateJackVCViewsIntrinsic;
@end

@implementation jackViewController
#pragma mark - Properties
@synthesize socket;
@synthesize faceDetector;
@synthesize ballonImageView;
@synthesize ballonTextLabel;

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    AppDelegate *dlg = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.socket       = dlg.socket;
    self.faceDetector = dlg.faceDetector;
}

- (void)viewDidUnload
{
    [self setBallonImageView:nil];
    [self setBallonTextLabel:nil];
    [super viewDidUnload];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // update view status    
    self.socket.delegate = self;
    [self updateJackVCViews];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // show warning dialog
    AppDelegate *dlg = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if( ! dlg.isWarningDialogShown) {
//        [self showWarningDialog];
        dlg.isWarningDialogShown = YES;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma mark - OTOplugDelegate methods
// bytes are available to be read (user can call read:)
-(void)readBytesAvailable:(int)length{}
-(void)sendBufferEmptyNotify{}

-(void)outputVolumeChanged:(float)volume
{
    [self updateJackVCViews];
}
-(void)headSetInOutChanged:(BOOL)isHeadSetIn isMicAvailable:(BOOL)isMicAvailable
{
    [self updateJackVCViews];
}
-(void)audioSessionInterrupted:(BOOL)interrupted
{
    [self updateJackVCViews];
}

#pragma mark - Protected methods
-(void)notifyIsSocketReady:(BOOL)isReady {}

#pragma mark - Private methods
-(BOOL)isHeadsetReady
{
    AudioPHY *phy = self.socket.audioPHY;    
    return phy.isHeadsetIn && phy.outputVolume >= 1.0;
}
-(void)showWarningDialog
{
    UIAlertView *alert = [[UIAlertView alloc]     
                          initWithTitle:@"警告" 
                          message:@"LED制御実験は適切な知識と指導の元で行なってください。\n特に光過敏性発作等の危険性への配慮が必要です。"
                          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];    
}
-(void)updateJackVCViews
{
    [UIView animateWithDuration:0.5 animations:^{
        [self updateJackVCViewsIntrinsic];
    }];
}
-(void)updateJackVCViewsIntrinsic
{
    bool isReady = YES;
    AudioPHY *phy = self.socket.audioPHY;
    
//NSLog(@"phy %@", phy);
    
    if(! phy.isHeadsetIn ) { // イヤホンが刺されていない 
        isReady = NO;

        ballonImageView.image = [UIImage imageNamed:@"ballon_up.png"];    
        ballonTextLabel.text = @"イヤホンを挿してください。";
    } else if(phy.outputVolume < 1.0) { // 音量設定不足
        isReady = NO;
        
        ballonImageView.image = [UIImage imageNamed:@"ballon_left.png"];
        ballonTextLabel.text = @"音量を最大にしてください。";        
//NSLog(@"%1.2f", phy.outputVolume);
    }

    // バルーンの表示/非表示
    ballonImageView.hidden = isReady;
    ballonTextLabel.hidden = isReady;
    
    [self notifyIsSocketReady:isReady];
}

@end
