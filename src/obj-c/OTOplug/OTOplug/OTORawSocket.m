//
//  OTORawSocket.m
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011 REINFORCE Lab. All rights reserved.
//

#import "OTORawSocket.h"
#import "OTOplugDelegate.h"
#import "SWMModem.h"
#import "AudioPHY.h"
#include "math.h"

@interface OTORawSocket()
-(void)onReceivePacket;
-(void)onSendBufferEmpty;
@end

@implementation OTORawSocket
@synthesize delegate = delegate_;
@synthesize audioPHY;

#pragma mark - Constructor
// initializer
-(id)initWithModem:(id<SWMModem>)_modem
{
    self = [super init];
    if(self) {
        modem_ = _modem;
        [modem_ setSocket:self];
        
        maxPacketSize_ = [_modem getMaxPacketSize];
        rcvBuf_ = calloc(maxPacketSize_, sizeof(uint8_t));
        rcvSize_ = 0;
        
        float samplingRate = [_modem getAudioSamplingRate];
        int audioBufferSize = [_modem getAudioBufferSize];
        self.audioPHY = [[AudioPHY alloc] initWithParameters:samplingRate audioBufferSize:audioBufferSize];
        self.audioPHY.delegate = self;
        self.audioPHY.modem    = _modem;

        [self.audioPHY start];
    }
    return self;
}
-(void)dealloc
{
    [self.audioPHY stop];
    free(rcvBuf_);
}
#pragma mark - Private methods
-(void)onReceivePacket
{
    if(rcvSize_ > 0 && [delegate_ respondsToSelector:@selector(readBytesAvailable:)]) {
        [delegate_ readBytesAvailable:rcvSize_];
    }
}
-(void)onSendBufferEmpty
{
    if([delegate_ respondsToSelector:@selector(sendBufferEmptyNotify)]){
        [delegate_ sendBufferEmptyNotify];
    }
}
#pragma mark - Public methods
-(int)write:(uint8_t *)buf length:(int)length
{
    return [modem_ sendPacket:buf length:length];
}
-(int)read:(uint8_t *)buf length:(int)length
{
    long len;
    @synchronized(self) {
        len = rcvSize_ < length ? rcvSize_ : length;
        memcpy(buf, rcvBuf_, len);
        rcvSize_ -= len;
    }
    return  len;
}
-(void)flush
{
}
#pragma mark - AudioPHYDelegate protocol
-(void)outputVolumeChanged:(float)volume
{
    if([delegate_ respondsToSelector:@selector(outputVolumeChanged:)]) {
        [delegate_ outputVolumeChanged:volume];
    }
}
-(void)headSetInOutChanged:(BOOL)isHeadSetIn 
{ 
    if([delegate_ respondsToSelector:@selector(headSetInOutChanged:isMicAvailable:)]){
        [delegate_ headSetInOutChanged:isHeadSetIn isMicAvailable:audioPHY.isMicAvailable];
    }
}
-(void)audioSessionInterrupted:(BOOL)interrupted
{
    if([delegate_ respondsToSelector:@selector(audioSessionInterrupted:)]) {
        [delegate_ audioSessionInterrupted:interrupted];
    }
}

#pragma mark - SWMSocket protocol
- (void)packetReceived:(uint8_t *)buf length:(int)length
{
    @synchronized(self) {
        if(rcvSize_ == 0) {
            rcvSize_ = length;
            memcpy(rcvBuf_, buf, length * sizeof(uint8_t));
        }
    }
    [self performSelectorOnMainThread:@selector(onReceivePacket) withObject:nil waitUntilDone:NO];
    /* debug, packet dump
     NSMutableString *sb = [[NSMutableString alloc] initWithCapacity:100];
     [sb appendFormat:@"Packet received: %d Packet:", length];
     for(int i = 0; i < length; i++) {
     [sb appendFormat:@"%02X,", buf[i]];
     }
     NSLog(@"%@", sb);
     [sb release];
     */
}
- (void)sendBufferEmptyNotify
{
    [self performSelectorOnMainThread:@selector(onSendBufferEmpty) withObject:nil waitUntilDone:NO];
}
@end
