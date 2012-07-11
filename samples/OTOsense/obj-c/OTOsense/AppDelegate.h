//
//  AppDelegate.h
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTOPacketSocket.h"
#import "FaceDetector.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) OTOPacketSocket *socket;
@property (strong, nonatomic) FaceDetector *faceDetector;
@property (assign, nonatomic) bool isWarningDialogShown;

@end
