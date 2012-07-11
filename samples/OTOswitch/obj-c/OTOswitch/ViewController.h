//
//  ViewController.h
//  OTOswitch
//
//  Created by 昭宏 上原 on 12/05/07.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTOplugDelegate.h"

@interface ViewController : UIViewController<OTOplugDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *connectStatusIcon;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *portStatusImageViews;
@property (weak, nonatomic) IBOutlet UILabel *connectStatusLabel;

@end
