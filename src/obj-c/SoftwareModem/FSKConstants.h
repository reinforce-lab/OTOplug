//
//  FSKConstants.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/28.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SWMConstants.h"

#define kFSKMaxPacketLength 127
#define kFSKBaudRate       1200
#define kFSKMark1Samples   36
#define kFSKMark0Samples   (kFSKMark1Samples *2)

// constants for implementation
#if TARGET_IPHONE_SIMULATOR
#define kFSKSliceLevel ((1 << kAudioUnitSampleFractionBits) / 250)
#else
#define kFSKSliceLevel ((1 << kAudioUnitSampleFractionBits) / 2.5)
#endif

#define kFSKAudioBufferLength 512
#define kFSKLostCarrierDuration   (kFSKMark0Samples * 1.5)
#define kFSKPulseWidthThreashold  (kFSKMark1Samples * 1.5)
// Modulator can have at leaset 2 packets in its buffer (data0/data1)
#define kFSKModulatorBufferLength (((int)(kFSKMark0Samples * 8 * (kFSKMaxPacketLength + 1 + 4) ) / kFSKAudioBufferLength +1) * kFSKAudioBufferLength)
// number of sync code to re-sync
#define kNumberOfReSyncCode 3
#define kFSKMaxFrameLength (kFSKMaxPacketLength + 1 )