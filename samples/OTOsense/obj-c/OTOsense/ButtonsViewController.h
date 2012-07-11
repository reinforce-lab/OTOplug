//
//  ButtonsViewController.h
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "jackViewController.h"
@interface ButtonsViewController : jackViewController

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *numButtons;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *numLabels;

@end
