//
//  PWMConstants.h
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/28.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//
#import <Foundation/Foundation.h>
@import AudioToolbox;

#define kSWMSamplingRate    44100.0
#define kSWMSyncCode        0x7e
#define kSWMMaxMark1Length  5

#define kPWMMaxPacketSize  32
#define kPWMMark1Samples   36
#define kPWMMark0Samples   (kPWMMark1Samples *2)
#define kPWMBaudRate       (kSWMSamplingRate / kPWMMark1Samples)

// constants for implementation
#define kPWMSliceLevel (1.0f / 250.0f)

#define kPWMAudioBufferSize 512
#define kPWMLostCarrierDuration   (kPWMMark0Samples * 1.5)
#define kPWMPulseWidthThreashold  (kPWMMark1Samples * 1.5)
// number of sync code to re-sync
#define kNumberOfReSyncCode 2
// Modulator can have at leaset 2 packets in its buffer (data0/data1)
#define kPWMModulatorBufferLength (((int)(kPWMMark0Samples * 8 * (kNumberOfReSyncCode + kPWMMaxPacketSize + 1 ) ) / kPWMAudioBufferSize +1) * kPWMAudioBufferSize)
