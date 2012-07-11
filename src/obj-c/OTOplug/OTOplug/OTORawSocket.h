//
//  OTORawSocket.h
//  OTOplug
//
//  Created by Uehara Akihiro on 11/09/02.
//  Copyright (c) 2011 REINFORCE Lab. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AudioPHYDelegate.h"
#import "SWMSocket.h"
#import "OTOplugDelegate.h"

@protocol SWMModem;
@class AudioPHY;

// Raw packet modem. 
// Every written packet is simply sent to a client without packet error detection.
// If reliable communication is necessary, use OTOPacketSocket.
@interface OTORawSocket : NSObject<AudioPHYDelegate, SWMSocket>
{
@protected
    id<SWMModem> modem_;
    int maxPacketSize_;
    int rcvSize_;
    uint8_t *rcvBuf_;
}

@property (unsafe_unretained, nonatomic) NSObject<OTOplugDelegate> *delegate;
@property (strong, nonatomic) AudioPHY *audioPHY;

// initializer
-(id)initWithModem:(id<SWMModem>)modem;

/*!
 @function write
 @param buf
 pointer of buffer to be send.
 @param length
 available length of the buffer in byte count.
 @return written data length. it returns zero if this can not write or some error occures.    
 */
-(int)write:(uint8_t *)buf length:(int)length;

/*!
 @function write
 @param buf
 pointer of buffer to be send.
 @param length
 available length of the buffer in byte count.
 @return written data length. it returns zero if this can not write or some error occures.    
 */
-(int)read:(uint8_t *)buf length:(int)length;

/*!
 @function flush
 @abstract Flush all tx/rx buffer data. If audio jack is not connected, tx buffer is simply cleared.
 */
-(void)flush;
@end
