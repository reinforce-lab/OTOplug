//
//  FaceDetector.h
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/19.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol FaceDetectorDelegate
-(void)detectionUpdated:(NSArray *)features;
@end

@interface FaceDetector : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (assign, nonatomic, readonly) BOOL isCameraAvailable; 
@property (weak, nonatomic)  id<FaceDetectorDelegate> delegate;

-(void)start:(UIView *)preview;
-(void)stop;
@end

