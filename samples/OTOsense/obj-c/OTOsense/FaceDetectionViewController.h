//
//  FaceDetectionViewController.h
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <AVFoundation/AVFoundation.h>
#import "jackViewController.h"

@interface FaceDetectionViewController : jackViewController<AVCaptureVideoDataOutputSampleBufferDelegate, FaceDetectorDelegate>
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UILabel *areaLabel;
@end
