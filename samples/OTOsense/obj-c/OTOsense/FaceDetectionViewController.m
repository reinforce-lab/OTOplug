//
//  FaceDetectionViewController.m
//  OTOsense
//
//  Created by 昭宏 上原 on 12/06/10.
//  Copyright (c) 2012年 REINFORCE Lab. All rights reserved.
//

#import "FaceDetectionViewController.h"
#import "PacketTypes.h"

@interface FaceDetectionViewController () {
    uint8_t buf_[5];
}
@end

@implementation FaceDetectionViewController
#pragma mark - life cycle
@synthesize positionLabel;
@synthesize preview;
@synthesize areaLabel;

-(void)viewWillAppear:(BOOL)animated
{
    [self.faceDetector start:(UIView *)self.preview];
    self.faceDetector.delegate = self;

    [super viewWillAppear:animated];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(! self.faceDetector.isCameraAvailable) {
        UIAlertView *alert = [[UIAlertView alloc]     
                              initWithTitle:@"警告" 
                              message:@"フロントカメラが有効ではありません。"
                              delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
}
-(void)viewWillDisappear:(BOOL)animated
{
    [self.faceDetector stop];

    [super viewWillDisappear:animated];
}

#pragma mark - Private methods
-(void)detectionUpdated:(NSArray *)features
{
     buf_[0] = FACE_PACKET_ID;
    for(int i=1; i < 5; i++) {
        buf_[i] = 0;
    }
    
    if([features count] == 0) { // 顔検出されない        
        areaLabel.text = @"(  0,  0)";        
        positionLabel.text = @"(  0,  0)";
    } else {
        CGRect r = [[features objectAtIndex:0] CGRectValue];
//NSLog(@"%@", NSStringFromCGRect(r));
        areaLabel.text = [NSString stringWithFormat:@"(% 3d,% 3d)", (int)r.size.width, (int)r.size.height];
        positionLabel.text = [NSString stringWithFormat:@"(% 3d,% 3d)", (int)r.origin.x, (int)r.origin.y];
        
        buf_[1] = (int)r.origin.x;
        buf_[2] = (int)r.origin.y;
        buf_[3] = (int)r.size.width;
        buf_[4] = (int)r.size.height;
    }

    [self.socket write:buf_ length:5];    
}
- (void)viewDidUnload {
    [self setPositionLabel:nil];
    [self setAreaLabel:nil];
    [self setPreview:nil];
    [super viewDidUnload];
}
@end