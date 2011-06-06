//
//  TestClientAppDelegate.h
//  TestClient
//
//  Created by 上原 昭宏 on 11/06/05.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TestClientViewController;

@interface TestClientAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet TestClientViewController *viewController;

@end
