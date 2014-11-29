//
//  OTOplugUtility.h
//  OTOplug
//
//  Created by AkihiroUehara on 2014/11/25.
//
//

#import <Foundation/Foundation.h>

@interface OTOplugUtility : NSObject
+(void)checkOSStatusError:(NSString *)message error:(OSStatus)error;
+(void)checkOSStatusError:(const char [])prettyFunction message:(NSString *)message error:(OSStatus)error ;

@end
