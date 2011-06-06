//
//  AudioPHY.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab.. All rights reserved.
//

#import "AudioPHY.h"

// Private methods
@interface AudioPHY ()
@property(nonatomic, assign) float outputVolume;
@property(nonatomic, assign) BOOL isHeadsetInOut;
-(void)checkOSStatusError:(NSString*)message error:(OSStatus)error;
-(void)prepareAudioSession:(int)audioBufferlength;
-(void)prepareAudioUnit;
@end

// function declarations
static void sessionPropertyChanged(void *inClientData,
								   AudioSessionPropertyID inID,
								   UInt32 inDataSize,
								   const void *inData);

@implementation AudioPHY
#pragma mark Properties
@synthesize outputVolume;
@synthesize isHeadsetInOut;
@synthesize isRunning;

#pragma mark constructor
-(id)initWithSocket:(NSObject<SWMPhysicalSocket> *)physicalSocket audioBufferLength:(int)audioBufferLength
{
    self = [super init];
	if(self) {
		socket_ = [physicalSocket retain];
		[self prepareAudioSession:audioBufferLength];
		[self prepareAudioUnit];
	}
	return self;
}

-(void)dealloc {
	// deallocating AudioUnit 
	[self stop]; // stopping audiounit

	// remove property listeners	
	AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, sessionPropertyChanged, self);
	AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, sessionPropertyChanged, self);
	
	AudioUnitUninitialize(audioUnit_);
	AudioComponentInstanceDispose(audioUnit_);

	[socket_ release];
	
	[super dealloc];
}

#pragma mark render callback
static OSStatus renderCallback(void * inRefCon,
							   AudioUnitRenderActionFlags* ioActionFlags,
							   const AudioTimeStamp* inTimeStamp,
							   UInt32 inBusNumber,
							   UInt32 inNumberFrames,
							   AudioBufferList* ioData) {
	AudioPHY* phy = (AudioPHY*) inRefCon;
	if(!phy->isRunning_) {
		return kAudioUnitErr_CannotDoInCurrentContext;
	}
	
	// render microphone 
	// refactoring: should allows an audio unit host application to tell an audio unit to use a specified buffer for its input callback.	
	OSStatus error = 
	AudioUnitRender(phy->audioUnit_,
					ioActionFlags,
					inTimeStamp,
					1, // microphone bus number
					inNumberFrames,
					ioData
					);
	[phy checkOSStatusError:@"Microphone audio rendering" error:error]; 	
	if(error) {
		return error;
	}
	
	// demodulate
	AudioUnitSampleType *outL = ioData->mBuffers[0].mData;
	AudioUnitSampleType *outR = ioData->mBuffers[1].mData;
	bzero(outR, inNumberFrames * sizeof(AudioUnitSampleType));
	[phy->socket_ demodulate:outL length:inNumberFrames];
	
	// modulate
	[phy->socket_ modulate:outL length:inNumberFrames]; 
	
	return noErr;
}
static void sessionInterruption(void *inClientData,
								UInt32 inInterruptionState)
{
	if(inInterruptionState == kAudioSessionBeginInterruption) {
		NSLog(@"Begin AudioSession interruption.");
	} else {
		NSLog(@"End AudioSession interruption.");
		AudioSessionSetActive(YES); // re-activate and re-start audio play&recording
	}
}
static void sessionPropertyChanged(void *inClientData,
								   AudioSessionPropertyID inID,
								   UInt32 inDataSize,
								   const void *inData)
{
	AudioPHY *phy = (AudioPHY *)inClientData;
	if(inID ==kAudioSessionProperty_CurrentHardwareOutputVolume ) {	
		float volume = *((float *)inData);
		dispatch_async(dispatch_get_main_queue(), ^{
			phy.outputVolume = volume;
//			NSLog(@"%s volume changed: %f", __func__, volume);
		});
	} else if( inID == kAudioSessionProperty_AudioRouteChange ) {
#if !(TARGET_IPHONE_SIMULATOR)
		UInt32 size = sizeof(CFStringRef);
		CFStringRef route;
		AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &route);
//		NSLog(@"%s route channged: %@", __func__, (NSString *)route );
		NSString *rt = (NSString *)route;
		dispatch_async(dispatch_get_main_queue(), ^{
			phy.isHeadsetInOut = [rt isEqualToString:@"HeadsetInOut"];
		});
#endif		
	}
}

#pragma mark private methods
-(void)checkOSStatusError:(NSString *)message error:(OSStatus)error
{
	if(error) {
		NSLog(@"AudioPHY error message:%@ OSStatus:%d.",message, (int)error);
	}
}
-(void)prepareAudioSession:(int)audioBufferLength
{
	OSStatus error;
	
	error = AudioSessionInitialize(NULL, NULL, sessionInterruption, self);
	[self checkOSStatusError:@"AudioSessionInitialize()" error:error];
	
	// Setting Audio Session Category (play and record)
	UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
	error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
							sizeof(sessionCategory),
							&sessionCategory);
	[self checkOSStatusError:@"AudioSessionSetProperty() sets category" error:error];

	// set hardware sampling rate
	/*
	Float64 sampleRate = kSWMSamplingRate;
	error = AudioSessionSetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, sizeof(Float64), &sampleRate);
	[self checkOSStatusError:@"AudioSessionSetProperty() sets currentHardwareSampleRate" error:error];
	*/
	
	// set audio buffer size
	Float32 duration = audioBufferLength / kSWMSamplingRate;
	error = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(Float32), &duration);
	[self checkOSStatusError:@"AudioSessionSetProperty() sets preferredHardwareIOBufferDuration" error:error];
	
	// read properties
	UInt32 size = sizeof(float);
	float volume;
	error = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume, &size, &volume);
	[self checkOSStatusError:@"AudioSessionGetProperty() current hardware volume." error:error];	
	self.outputVolume = volume;

#if TARGET_IPHONE_SIMULATOR
	self.isHeadsetInOut = true;
#else // TARGET_IOS_IPHONE
	size = sizeof(CFStringRef);
	CFStringRef route;
	error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &route);
	[self checkOSStatusError:@"AudioSessionGetProperty() audio route." error:error];
	NSString *rt = (NSString *)route;
	self.isHeadsetInOut = [rt isEqualToString:@"HeadsetInOut"];
#endif
	
	// add property listener
	AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, sessionPropertyChanged, self);
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, sessionPropertyChanged, self);
	
	// activation
	error = AudioSessionSetActive( YES );
	[self checkOSStatusError:@"AudioSessionSetActive()" error:error];
}
-(void)prepareAudioUnit
{
	OSStatus error;
	//Getting RemoteIO Audio Unit (speaker out) AudioComponentDescription
    AudioComponentDescription cd;
	{
		cd.componentType = kAudioUnitType_Output;
		cd.componentSubType = kAudioUnitSubType_RemoteIO;
		cd.componentManufacturer = kAudioUnitManufacturer_Apple;
		cd.componentFlags = 0;
		cd.componentFlagsMask = 0;
	}
    
    //Getting AudioComponent
    AudioComponent component = AudioComponentFindNext(NULL, &cd);
	
    //Getting audioUnit
    error = AudioComponentInstanceNew(component, &audioUnit_);
	[self checkOSStatusError:@"AudioComponentInstanceNew" error:error];

	// turning on a microphone
	UInt32 enableOutput = 1; // TRUE
	error = AudioUnitSetProperty(audioUnit_,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Input,
						 1, // microphone
						 &enableOutput,
						 sizeof(enableOutput));
	[self checkOSStatusError:@"AudioUnitSetProperty() turning on microphone" error:error];
	
    // sets a callback method
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback; //callback method
    callbackStruct.inputProcRefCon = self;// data pointer reffered in the callback method    
    error = AudioUnitSetProperty(audioUnit_, 
                         kAudioUnitProperty_SetRenderCallback,                          
                         kAudioUnitScope_Input, //input port of the speaker
                         0,   // speaker
                         &callbackStruct,
                         sizeof(AURenderCallbackStruct));
	[self checkOSStatusError:@"AduioUnitSetProperty sets a callback method" error:error];
    
	// applying speaker-out audio format, stereo channels
    AudioStreamBasicDescription audioFormat;
	{
		audioFormat.mSampleRate         = kSWMSamplingRate;
		audioFormat.mFormatID           = kAudioFormatLinearPCM;
		audioFormat.mFormatFlags        = kAudioFormatFlagsAudioUnitCanonical;
		audioFormat.mChannelsPerFrame   = 2;
		audioFormat.mBytesPerPacket     = sizeof(AudioUnitSampleType);
		audioFormat.mBytesPerFrame      = sizeof(AudioUnitSampleType);
		audioFormat.mFramesPerPacket    = 1;
		audioFormat.mBitsPerChannel     = 8 * sizeof(AudioUnitSampleType);
		audioFormat.mReserved           = 0;
	}    
    error = AudioUnitSetProperty(audioUnit_,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, // input port of the speaker
                         0, // speaker
                         &audioFormat,
                         sizeof(audioFormat));
	[self checkOSStatusError:@"AudioUnitSetProperty() sets speaker audio format" error:error];

	// applying microphone audio format, monoral channel
	//	audioFormat.mChannelsPerFrame = 1;
	error = AudioUnitSetProperty(audioUnit_,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Output,
						 1, // microphone
						 &audioFormat,
						 sizeof(audioFormat));
	[self checkOSStatusError:@"AudioUnitSetProperty() sets microphone audio format" error:error];

	//AudioUnit initialization
    error = AudioUnitInitialize(audioUnit_);
	[self checkOSStatusError:@"AudioUnitInitialize" error:error];	
	/*
	uint flag = 0;
	AudioUnitGetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Input, 0, &flag, sizeof(uint));
	NSLog(@"Should allocate buffer is %d.\n",flag);	*/
}

#pragma mark public methods
-(void)start
{
	if(!isRunning_){
		AudioOutputUnitStart(audioUnit_);
		isRunning_ = TRUE;
	}
}
-(void)stop
{
	if(isRunning_) {
		AudioOutputUnitStop(audioUnit_);
		isRunning_ = FALSE;
	}
}
@end
