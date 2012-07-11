//
//  SensorsViewController.h
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "jackViewController.h"
@interface SensorsViewController : jackViewController

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *acsViews;
@property (weak, nonatomic) IBOutlet UIButton *acsButton;


@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *gyroViews;
@property (weak, nonatomic) IBOutlet UIButton *gyroButton;

@property (weak, nonatomic) IBOutlet UIButton *compassButton;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *compassViews;

@property (weak, nonatomic) IBOutlet UIButton *faceDetectionButton;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *faceDetectionViews;

- (IBAction)acsButtonTouchUpInside:(id)sender;
- (IBAction)gyroButtonTouchUpInside:(id)sender;
- (IBAction)compassButtonTouchUpInside:(id)sender;
- (IBAction)faceDetButtonTouchUpInside:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *acsXLabel;
@property (weak, nonatomic) IBOutlet UILabel *acsYLabel;
@property (weak, nonatomic) IBOutlet UILabel *acsZLabel;

@property (weak, nonatomic) IBOutlet UILabel *gyroXLabel;
@property (weak, nonatomic) IBOutlet UILabel *gyroYLabel;
@property (weak, nonatomic) IBOutlet UILabel *gyroZLabel;
@property (weak, nonatomic) IBOutlet UILabel *compassDegreeLabel;

@property (weak, nonatomic) IBOutlet UILabel *facePosLabel;
@property (weak, nonatomic) IBOutlet UILabel *faceAreaLabel;

@end
