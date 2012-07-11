//
//  jackViewController.h
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTOPacketSocket.h"
#import "FaceDetector.h"

@interface jackViewController : UIViewController<OTOplugDelegate>

@property (weak, nonatomic) OTOPacketSocket *socket;
@property (weak, nonatomic) FaceDetector *faceDetector;

@property (weak, nonatomic) IBOutlet UIImageView *ballonImageView;
@property (weak, nonatomic) IBOutlet UILabel *ballonTextLabel;

-(void)notifyIsSocketReady:(BOOL)isReady;

@end
