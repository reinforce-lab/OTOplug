//
//  FSKModem.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab.. All rights reserved.
//
#import "FSKModem.h"

@interface FSKModem (Private)
-(Byte)calculateCRC8:(Byte[])buf length:(int)length;
-(void)invokeBufferBecameEmptyCallback;
-(void)invokeReceivePacketCallback;
@end

// constant definisitions
@implementation FSKModem
#pragma mark Properties	
@synthesize audioPHY = phy_;
@synthesize modulator = modulator_;
@dynamic signalLevel;
-(AudioUnitSampleType)getSignalLevel
{
	return demodulator_.signalLevel;
}
@dynamic mute;
-(BOOL)getMute
{
	return modulator_.mute;
}
-(void)setMute:(BOOL)value
{
	modulator_.mute = value;
}

#pragma mark Constructor
- (id)initWithSocketWithoutPHY:(NSObject<SWMSocket> *)socket
{
    self = [super init];
	if(self) {
		socket_ = [socket retain];
		modulator_ = [[FSKModulator alloc] initWithSocket:self];
		demodulator_ = [[FSKDemodulator alloc] initWithSocket:self];
	}
	return self;
}
- (id)initWithSocket:(NSObject<SWMSocket> *)socket
{
    self = [super init];
	if(self) {
		socket_ = [socket retain];
		modulator_ = [[FSKModulator alloc] init];
		demodulator_ = [[FSKDemodulator alloc] initWithSocket:self];
		phy_ = [[AudioPHY alloc] initWithSocket:self audioBufferLength:kFSKAudioBufferLength];
	}
   return self;
}

-(void)dealloc {
	[phy_ release];
	[demodulator_ release];
	[modulator_ release];
	[socket_ release];
	
	[super dealloc];
}
#pragma mark Private methods
Byte crc_ibutton_update(Byte crc, Byte data)
{
	Byte i;
	crc = (Byte)(crc ^ data);
	for (i = 0; i < 8; i++)
	{
		if ((crc & 0x01) != 0)
			crc = (Byte)((crc >> 1) ^ 0x8c);
		else
			crc >>= 1;
	}
	return crc;
}
-(Byte)calculateCRC8:(Byte[])buf length:(int)length
{
	Byte cc = 0;
	for(int i=0; i < length;i++) {
		cc = crc_ibutton_update(cc, buf[i]);
	}
	return cc;
}
#pragma mark SWMPhysicalSocket 
-(void)demodulate:(AudioUnitSampleType *)buf length:(int)length
{
	[demodulator_ demodulate:buf length:length];
}
-(void)modulate:(AudioUnitSampleType *)buf length:(UInt32)length
{
	[modulator_ modulate:buf length:length];
}
#pragma mark Public methods
- (void)start
{
	[phy_ start];
}
- (void)stop
{
	[phy_ stop];
}
- (int)sendPacket:(Byte *)buf length:(int)length
{
	Byte cc = [self calculateCRC8:buf length:length];
	return [modulator_ sendPacket:buf length:length checksum:cc];
}
- (void)packetReceived:(Byte *)buf length:(int)length
{
	Byte cc = [self calculateCRC8:buf length:length];
//	NSLog(@"CRC8: %02x", buf[length -1]);
	if(cc == 0) {
/* debug, packet dump
		NSMutableString *sb = [[NSMutableString alloc] initWithCapacity:100];
		[sb appendFormat:@"Packet received: %d Packet:", length];
		 for(int i = 0; i < length; i++) {
			 [sb appendFormat:@"%02X,", buf[i]];
		 }
		 NSLog(@"%@", sb);
		[sb release];
*/
		int newBufLength = length -1;
		Byte *newBuf = calloc(newBufLength, sizeof(AudioUnitSampleType));		
		memcpy(newBuf, buf, newBufLength * sizeof(AudioUnitSampleType));
		dispatch_async(dispatch_get_main_queue(), ^{
			[socket_ packetReceived:newBuf length:newBufLength];
			free(newBuf);
		});
	} else {
/* debug, packet dump		
		NSMutableString *sb = [[NSMutableString alloc] initWithCapacity:200];
		[sb appendFormat:@"ERROR packetReceived:length:%d", length];
		for(int i=0; i < length; i++) {
			[sb appendFormat:@" %02x", buf[i]];
		}
		[sb appendFormat:@" expected checksum %02x", [self calculateCRC8:buf length:length -1]];
		NSLog(@"%@", sb);
		[sb release];
*/ 
	}

}
- (void)sendBufferEmptyNotify
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[socket_ sendBufferEmptyNotify];
	});
}
@end
