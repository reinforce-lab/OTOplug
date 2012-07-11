//
//  SensorsViewController.m
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import "SensorsViewController.h"
#import "PacketTypes.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface SensorsViewController () {
	CMMotionManager	  *motionMgr;
    CLLocationManager *locMgr;
    int switchStat_;
    Byte buf_[32];
    
    BOOL isAcsEnabled_;
    BOOL isGyroEnabled_;
    BOOL isCompassEnabled_;
    BOOL isFaceDetEnabled_;
}
-(void)setupViewStatus;

-(void)setupAcsViews:(BOOL)enabled;
-(void)setupGyroViews:(BOOL)enabled;
-(void)setupCompassViews:(BOOL)enabled;
-(void)setupFaceDetViews:(BOOL)enabled;

-(int8_t)convAcsVal:(double)acsValue;
-(int8_t)convGyrVal:(double)gyrValue;
-(uint8_t)convMgnVal:(double)mgnValue;
@end

@implementation SensorsViewController
@synthesize acsYLabel;
@synthesize acsZLabel;
@synthesize gyroXLabel;
@synthesize gyroYLabel;
@synthesize gyroZLabel;
@synthesize compassDegreeLabel;
@synthesize facePosLabel;
@synthesize faceAreaLabel;
@synthesize acsXLabel;
@synthesize acsViews;
@synthesize acsButton;
@synthesize gyroViews;
@synthesize gyroButton;
@synthesize compassButton;
@synthesize compassViews;
@synthesize faceDetectionButton;
@synthesize faceDetectionViews;

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view.
    locMgr    = [[CLLocationManager alloc] init];
    motionMgr = [[CMMotionManager alloc] init]; 
    [self setupViewStatus];
}

- (void)viewDidUnload
{
    [self setAcsButton:nil];
    [self setAcsViews:nil];
    [self setAcsViews:nil];
    [self setGyroViews:nil];
    [self setAcsButton:nil];
    [self setGyroButton:nil];
    [self setCompassButton:nil];
    [self setCompassViews:nil];
    [self setFaceDetectionButton:nil];
    [self setFaceDetectionViews:nil];
    [self setAcsXLabel:nil];
    [self setAcsYLabel:nil];
    [self setAcsZLabel:nil];
    [self setGyroXLabel:nil];
    [self setGyroYLabel:nil];
    [self setGyroZLabel:nil];
    [self setCompassDegreeLabel:nil];
    [self setFacePosLabel:nil];
    [self setFaceAreaLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

#pragma mark - OTOplugDelegate methods
// bytes are available to be read (user can call read:)
//-(void)readBytesAvailable:(int)length{}
-(void)sendBufferEmptyNotify
{
    int len = 0;
    CMAcceleration acsd;
    CMRotationRate gyrd;
    CLLocationDirection cmpd; 
    switch (switchStat_) {
        case 1: // 加速度
            if( isAcsEnabled_) {
                acsd = motionMgr.accelerometerData.acceleration;
                len = 4;
                buf_[0] = ACCS_PACKET_ID;            
                buf_[1] = [self convAcsVal:acsd.x];
                buf_[2] = [self convAcsVal:acsd.y];
                buf_[3] = [self convAcsVal:acsd.z];
                acsXLabel.text = [NSString stringWithFormat:@"% 01.2lf", acsd.x];
                acsYLabel.text = [NSString stringWithFormat:@"% 01.2lf", acsd.y];
                acsZLabel.text = [NSString stringWithFormat:@"% 01.2lf", acsd.z];
            }
            break;
        case 2: // ジャイロ
            if(isGyroEnabled_) {
                gyrd = motionMgr.gyroData.rotationRate;
                len = 4;
                buf_[0] = GYRO_PACKET_ID;
                buf_[1] = [self convGyrVal:gyrd.x];
                buf_[2] = [self convGyrVal:gyrd.y];
                buf_[3] = [self convGyrVal:gyrd.z];            
                gyroXLabel.text = [NSString stringWithFormat:@"% 01.2lf", gyrd.x];
                gyroYLabel.text = [NSString stringWithFormat:@"% 01.2lf", gyrd.y];
                gyroZLabel.text = [NSString stringWithFormat:@"% 01.2lf", gyrd.z];
            }
            break;
        case 3: // コンパス
            if(isCompassEnabled_) {
                cmpd = locMgr.heading.magneticHeading;
                len = 2;
                buf_[0] = COMP_PACKET_ID;
                buf_[1] = [self convMgnVal:cmpd];
                compassDegreeLabel.text = [NSString stringWithFormat:@"%-3.0lf", cmpd];
            }
            break;
        case 4: // 顔検出
            if(isFaceDetEnabled_) {
                buf_[0] = FACE_PACKET_ID;
                len = 0;
            }
            break;
        default:
            switchStat_ = 0; 
            break;
    }
    switchStat_++;
    if(len > 0) {
        [self.socket write:buf_ length:len];
    }
}

//-(void)outputVolumeChanged:(float)volume {}
//-(void)headSetInOutChanged:(BOOL)isHeadSetIn isMicAvailable:(BOOL)isMicAvailable {}
//-(void)audioSessionInterrupted:(BOOL)interrupted{}

#pragma mark - Protected methods
-(void)notifyIsSocketReady:(BOOL)isReady {
    [self setupViewStatus];
}

#pragma mark - Event handler
- (IBAction)acsButtonTouchUpInside:(id)sender {
    isAcsEnabled_ = !isAcsEnabled_;
    [self setupAcsViews:isAcsEnabled_];
}
- (IBAction)gyroButtonTouchUpInside:(id)sender {
    isGyroEnabled_ = ! isGyroEnabled_;
    [self setupGyroViews:isGyroEnabled_];
}
- (IBAction)compassButtonTouchUpInside:(id)sender {
    isCompassEnabled_ = !isCompassEnabled_;
    [self setupCompassViews:isCompassEnabled_];
}
- (IBAction)faceDetButtonTouchUpInside:(id)sender {
    isFaceDetEnabled_ = ! isFaceDetEnabled_;
    [self setupFaceDetViews:isFaceDetEnabled_];
}
#pragma mark - Private methods
-(void)setupViewStatus
{
    // 加速度ViewのEnable/Disable設定
    bool isAvailable = motionMgr.accelerometerAvailable;
    [self setupAcsViews:isAvailable]; 
    acsButton.userInteractionEnabled = isAvailable;
    if(isAvailable) {
        [motionMgr startAccelerometerUpdates];
    } 
    
    // Gyro
    isAvailable = motionMgr.gyroAvailable;
    [self setupGyroViews:isAvailable];
    gyroButton.userInteractionEnabled = isAvailable;
    if(isAvailable) {
        [motionMgr startGyroUpdates];        
    }
    
    // コンパス    
    isAvailable = [CLLocationManager headingAvailable];
    [self setupCompassViews:isAvailable];
    compassButton.userInteractionEnabled = isAvailable;
    if(isAvailable) {
        [locMgr startUpdatingHeading];
    }

    //顔検出
//    isAvailable = motionMgr.magnetometerAvailable;
    isAvailable = NO;    
    [self setupFaceDetViews:isAvailable];
    faceDetectionButton.userInteractionEnabled = isAvailable;
}
-(void)setupAcsViews:(BOOL)enabled {
    isAcsEnabled_ = enabled;
    
    float alpha = enabled ? 1.0 : 0.5;
    for(UIView *v in acsViews) {        
        v.alpha = alpha;
    }
    acsXLabel.text = @"0.00";
    acsYLabel.text = @"0.00";
    acsZLabel.text = @"0.00";
}
-(void)setupGyroViews:(BOOL)enabled {
    isGyroEnabled_ = enabled;
    
    float alpha = enabled ? 1.0 : 0.5;
    for(UIView *v in gyroViews) {
        v.alpha = alpha;
    }
    gyroXLabel.text = @"0.00";
    gyroYLabel.text = @"0.00";
    gyroZLabel.text = @"0.00";
}
-(void)setupCompassViews:(BOOL)enabled
{
    isCompassEnabled_ = enabled;
    
    float alpha = enabled ? 1.0 : 0.5;
    for(UIView *v in compassViews) {
        v.alpha = alpha;
    }
    compassDegreeLabel.text = @"000";
}
-(void)setupFaceDetViews:(BOOL)enabled
{
    isFaceDetEnabled_ = enabled;
    
    float alpha = enabled ? 1.0 : 0.5;
    for(UIView *v in faceDetectionViews) {
        v.alpha = alpha;
    }
    facePosLabel.text  = @"(  0,  0)";
    faceAreaLabel.text = @"(  0,  0)";
}
-(int8_t)convAcsVal:(double)value
{
    // 正規化
    value = value / 2.0; 
    // 値域制約
    value = MAX(-1.0, value); 
    value = MIN( 1.0, value);
    return (int8_t)(127 * value);
}
-(int8_t)convGyrVal:(double)value
{
    // 正規化
    value = value / 8.0; 
    // 値域制約
    value = MAX(-1.0, value); 
    value = MIN( 1.0, value);
    return (int8_t)(127 * value);    
}
-(uint8_t)convMgnVal:(double)value
{
    return value / 2.0;
}
@end
