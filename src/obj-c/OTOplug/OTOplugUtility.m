//
//  OTOplugUtility.m
//  OTOplug
//
//  Created by AkihiroUehara on 2014/11/25.
//
//

#import "OTOplugUtility.h"

@implementation OTOplugUtility

+(void)checkOSStatusError:(NSString *)message error:(OSStatus)error {
    if(error) {
        char code[5];
        *((SInt32*)&code[0]) = error;
        code[4] = 0;
        NSError *e = [NSError errorWithDomain:NSOSStatusErrorDomain code:error userInfo:nil];
        NSLog(@"AudioPHY error message:%@ OSStatus:%d code:%s error:%@.",message, (int)error, code, [e description]);
    }
}

+(void)checkNSError:(NSString *)message error:(NSError *)error {
    if(error != nil) {
        NSLog(@"AudioPHY error message:%@ error:%@.", message, [error description]);
    }
}

+(void)checkOSStatusError:(const char [])prettyFunction message:(NSString *)message error:(OSStatus)error {
    if(error) {
        [OTOplugUtility checkOSStatusError:[NSString stringWithFormat:@"%s %@", prettyFunction, message] error:error];
    }
}

@end
