//
//  AudioPHY.m
//  SoftwareModem
//
//  Created by UEHARA AKIHIRO on 10/11/23.
//  Copyright 2010 REINFORCE Lab. All rights reserved.
//

@import AudioToolbox;
#import "OTOplugUtility.h"
#import "AudioPHYDelegate.h"
#import "AudioPHY.h"
#import "SWMModem.h"

// FIXME オーディオのサンプルタイプはFloat32に統一(iOS8以降)
// Private methods
@interface AudioPHY ()
{
    AudioUnit audioUnit_;
    float outputVolume_;
    BOOL isHeadsetIn_;
    BOOL isInterrupted_; 
}

@property(nonatomic, assign) float outputVolume;
@property(nonatomic, assign) BOOL isHeadsetIn;
@property(nonatomic, assign) BOOL isMicAvailable;
@property(nonatomic, assign) BOOL isInterrupted;
@property(nonatomic, assign) BOOL isRunning;

-(void)setIsHeadSetInWP:(NSString *)route;
-(void)setVolumeWP:(NSNumber *)volume;
-(void)setIsAudioSessionInterruptedWP:(NSNumber *)isInterrupted;

-(float)outputVolume;
-(void)setOutputVolume:(float)outputVolume;
-(BOOL)isHeadsetIn;
-(void)setIsHeadsetIn:(BOOL)isHeadsetIn;
-(BOOL)isInterrupted;
-(void)setIsInterrupted:(BOOL)isInterrupted;

-(void)prepareAudioSession:(float)samplingRate audioBufferSize:(int)audioBufferSize;
-(void)prepareAudioUnit:(float)samplingRate;
@end

// function declarations
static void sessionPropertyChanged(void *inClientData,
								   AudioSessionPropertyID inID,
								   UInt32 inDataSize,
								   const void *inData);

@implementation AudioPHY
#pragma mark - Properties
@synthesize delegate;
@synthesize modem;

@dynamic outputVolume;
@dynamic isHeadsetIn;
@synthesize isMicAvailable;
@dynamic isInterrupted;

@synthesize isRunning;

-(float)outputVolume
{
    return outputVolume_;
}
-(void)setOutputVolume:(float)outputVolume
{
    outputVolume_ = outputVolume;
    [self.modem outputVolumeChanged:outputVolume_];
    [self.delegate outputVolumeChanged:outputVolume_];
}
-(BOOL)isHeadsetIn
{
    return isHeadsetIn_;
}
-(void)setIsHeadsetIn:(BOOL)isHeadsetIn
{
    isHeadsetIn_ = isHeadsetIn;
    [self.modem headSetInOutChanged:isHeadsetIn_];
    [self.delegate headSetInOutChanged:isHeadsetIn_];
}
-(BOOL)isInterrupted
{
    return isInterrupted_;
}
-(void)setIsInterrupted:(BOOL)isInterrupted
{
    isInterrupted_ = isInterrupted;
    [self.modem audioSessionInterrupted:isInterrupted_];
    [self.delegate audioSessionInterrupted:isInterrupted_];
}

#pragma mark - Constructor
-(id)initWithSamplingRate:(float)samplingRate audioBufferSize:(int)audioBufferSize
{
    self = [super init];
	if(self) {
		[self prepareAudioSession:samplingRate audioBufferSize:audioBufferSize];
		[self prepareAudioUnit:samplingRate];
	}
	return self;
}

-(void)dealloc {
	// deallocating AudioUnit 
	[self stop]; // stopping audiounit

	// remove property listeners	
	AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_CurrentHardwareOutputVolume, sessionPropertyChanged, (__bridge void *)self);
	AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, sessionPropertyChanged, (__bridge void*)self);
	
	AudioUnitUninitialize(audioUnit_);
	AudioComponentInstanceDispose(audioUnit_);
}

#pragma mark render callback
static OSStatus renderCallback(void * inRefCon,
							   AudioUnitRenderActionFlags* ioActionFlags,
							   const AudioTimeStamp* inTimeStamp,
							   UInt32 inBusNumber,
							   UInt32 inNumberFrames,
							   AudioBufferList* ioData) 
{
	AudioPHY* phy = (__bridge AudioPHY*) inRefCon;
	if(!phy.isRunning) {
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
    [OTOplugUtility checkOSStatusError:__PRETTY_FUNCTION__  message:@"Microphone audio rendering" error:error];
	if(error) {
		return error;
	}
	
	// demodulate
	Float32 *outL = ioData->mBuffers[0].mData;
	Float32 *outR = ioData->mBuffers[1].mData;
	[phy.modem demodulate:inNumberFrames buf:outL];
	
	// modulate
	[phy.modem modulate:inNumberFrames leftBuf:outL rightBuf:outR];
	
// clear right channel
//	bzero(outR, inNumberFrames * sizeof(Float32));
    
	return noErr;
}
static void sessionInterruption(void *inClientData,
								UInt32 inInterruptionState)
{
    AudioPHY *phy = (__bridge AudioPHY *)inClientData;
	if(inInterruptionState == kAudioSessionBeginInterruption) {
        [phy performSelectorOnMainThread:@selector(setIsAudioSessionInterruptedWP:)  withObject:[NSNumber numberWithBool:YES] waitUntilDone:NO];
		NSLog(@"Begin AudioSession interruption.");
	} else {
		NSLog(@"End AudioSession interruption.");
		AudioSessionSetActive(YES); // re-activate and re-start audio play&recording
        [phy performSelectorOnMainThread:@selector(setIsAudioSessionInterruptedWP:) withObject:[NSNumber numberWithBool:NO] waitUntilDone:NO];
	}
}
static void sessionPropertyChanged(void *inClientData,
								   AudioSessionPropertyID inID,
								   UInt32 inDataSize,
								   const void *inData)
{
	AudioPHY *phy = (__bridge AudioPHY *)inClientData;
	if(inID ==kAudioSessionProperty_CurrentHardwareOutputVolume ) {	
		float volume = *((float *)inData);
        [phy performSelectorOnMainThread:@selector(setVolumeWP:) withObject:[NSNumber numberWithFloat:volume] waitUntilDone:false];
	} else if( inID == kAudioSessionProperty_AudioRouteChange ) {
#if !(TARGET_IPHONE_SIMULATOR)
		UInt32 size = sizeof(CFStringRef);
		CFStringRef route;
		AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &route);
//NSLog(@"%s route channged: %@", __func__, (__bridge NSString *)route );
		NSString *rt = (__bridge_transfer NSString *)route;
        [phy performSelectorOnMainThread:@selector(setIsHeadSetInWP:)  withObject:rt waitUntilDone:false];
#endif		
	}
}

#pragma mark - private methods
-(void)setIsAudioSessionInterruptedWP:(NSNumber *)isInt
{
    self.isInterrupted = [isInt boolValue];
}
-(void)setIsHeadSetInWP:(NSString *)rt
{
    self.isMicAvailable = [rt isEqualToString:@"HeadsetInOut"] || [rt isEqualToString:@"HeadphonesAndMicrophone"];
	self.isHeadsetIn    = [rt isEqualToString:@"HeadsetInOut"] || [rt isEqualToString:@"HeadphonesAndMicrophone"];
}
-(void)setVolumeWP:(NSNumber *)volume
{
    self.outputVolume = [volume floatValue];
}

-(void)prepareAudioSession:(float)samplingRate audioBufferSize:(int)audioBufferSize
{
	OSStatus error;
	
	error = AudioSessionInitialize(NULL, NULL, sessionInterruption, (__bridge void*)self);
	[OTOplugUtility checkOSStatusError:@"AudioSessionInitialize()" error:error];
	
	// Setting Audio Session Category (play and record)
	UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
	error = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
							sizeof(sessionCategory),
							&sessionCategory);
	[OTOplugUtility checkOSStatusError:@"AudioSessionSetProperty() sets category" error:error];

	// set hardware sampling rate
	/*
	Float64 sampleRate = kSWMSamplingRate;
	error = AudioSessionSetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, sizeof(Float64), &sampleRate);
	[OTOplugUtility checkOSStatusError:@"AudioSessionSetProperty() sets currentHardwareSampleRate" error:error];
	*/
	
	// set audio buffer size
	Float32 duration = audioBufferSize / samplingRate;
	error = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(Float32), &duration);
	[OTOplugUtility checkOSStatusError:@"AudioSessionSetProperty() sets preferredHardwareIOBufferDuration" error:error];
	
	// read properties
	UInt32 size = sizeof(float);
	float volume;
	error = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputVolume, &size, &volume);
	[OTOplugUtility checkOSStatusError:@"AudioSessionGetProperty() current hardware volume." error:error];	
	self.outputVolume = volume;

#if TARGET_IPHONE_SIMULATOR
    self.isMicAvailable = true;
	self.isHeadsetIn = true;
#else // TARGET_IOS_IPHONE
	size = sizeof(CFStringRef);
	CFStringRef route;
	error = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &route);
	[OTOplugUtility checkOSStatusError:@"AudioSessionGetProperty() audio route." error:error];
	NSString *rt = (__bridge_transfer NSString *)route;

    [self setIsHeadSetInWP:rt];
#endif
	
	// add property listener
	AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume, sessionPropertyChanged, (__bridge void*)self);
	AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, sessionPropertyChanged, (__bridge void*)self);
	
	// activation
	error = AudioSessionSetActive( YES );
	[OTOplugUtility checkOSStatusError:@"AudioSessionSetActive()" error:error];
}
-(void)prepareAudioUnit:(float)samplingRate
{
    // applying speaker-out audio format, stereo channels
    _outputFormat.mSampleRate         = samplingRate;
    _outputFormat.mFormatID           = kAudioFormatLinearPCM;
    _outputFormat.mFormatFlags        = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked |  kAudioFormatFlagIsNonInterleaved;
    // フレームはAudioUnitの最小のデータ単位。L/Rの2チャンネル分のデータがあるので、2をかける。
    _outputFormat.mChannelsPerFrame   = 2;
    _outputFormat.mBytesPerFrame      = sizeof(Float32);
    // パケットはフレームの集まり。Linear PCMでは常に1パケット1フレーム。MP3などでは異なるが。
    _outputFormat.mFramesPerPacket    = 1;
    _outputFormat.mBytesPerPacket     = sizeof(Float32);
    _outputFormat.mBitsPerChannel     = 8 * sizeof(Float32);
    _outputFormat.mReserved           = 0;    
    
    // マイク入力のASBD。入力は1チャネルしかない。
    AudioStreamBasicDescription inputFormat;
    inputFormat.mSampleRate         = samplingRate;
    inputFormat.mFormatID           = kAudioFormatLinearPCM;
    inputFormat.mFormatFlags        = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked |  kAudioFormatFlagIsNonInterleaved;
    inputFormat.mChannelsPerFrame   = 2;
    inputFormat.mBytesPerFrame      = sizeof(Float32);
    inputFormat.mFramesPerPacket    = 1;
    inputFormat.mBytesPerPacket     = sizeof(Float32);
    inputFormat.mBitsPerChannel     = 8 * sizeof(Float32);
    inputFormat.mReserved           = 0;
    
	OSStatus error;
	//Getting RemoteIO Audio Unit (speaker out) AudioComponentDescription
    AudioComponentDescription cd;
	{
		cd.componentType         = kAudioUnitType_Output;
		cd.componentSubType      = kAudioUnitSubType_RemoteIO;
		cd.componentManufacturer = kAudioUnitManufacturer_Apple;
		cd.componentFlags        = 0;
		cd.componentFlagsMask    = 0;
	}
    
    //Getting AudioComponent
    AudioComponent component = AudioComponentFindNext(NULL, &cd);
	
    //Getting audioUnit
    error = AudioComponentInstanceNew(component, &audioUnit_);
	[OTOplugUtility checkOSStatusError:@"AudioComponentInstanceNew" error:error];

	// turning on a microphone
	UInt32 enableOutput = 1; // TRUE
	error = AudioUnitSetProperty(audioUnit_,
						 kAudioOutputUnitProperty_EnableIO,
						 kAudioUnitScope_Input,
						 1, // microphone
						 &enableOutput,
						 sizeof(enableOutput));
	[OTOplugUtility checkOSStatusError:@"AudioUnitSetProperty() turning on microphone" error:error];
	
    // sets a callback method
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = renderCallback; //callback method
    callbackStruct.inputProcRefCon = (__bridge void*) self;// data pointer reffered in the callback method    
    error = AudioUnitSetProperty(audioUnit_, 
                         kAudioUnitProperty_SetRenderCallback,                          
                         kAudioUnitScope_Input, //input port of the speaker
                         0,   // speaker
                         &callbackStruct,
                         sizeof(AURenderCallbackStruct));
	[OTOplugUtility checkOSStatusError:@"AduioUnitSetProperty sets a callback method" error:error];

    error = AudioUnitSetProperty(audioUnit_,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input, // input port of the speaker
                         0, // speaker
                         &_outputFormat,
                         sizeof(_outputFormat));
	[OTOplugUtility checkOSStatusError:@"AudioUnitSetProperty() sets speaker audio format" error:error];

	// applying microphone audio format, monoral channel
	//	audioFormat.mChannelsPerFrame = 1;
	error = AudioUnitSetProperty(audioUnit_,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Output,
						 1, // microphone
						 &inputFormat,
						 sizeof(inputFormat));
	[OTOplugUtility checkOSStatusError:@"AudioUnitSetProperty() sets microphone audio format" error:error];

	//AudioUnit initialization
    error = AudioUnitInitialize(audioUnit_);
	[OTOplugUtility checkOSStatusError:@"AudioUnitInitialize" error:error];	
	/*
	uint flag = 0;
	AudioUnitGetProperty(audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Input, 0, &flag, sizeof(uint));
	NSLog(@"Should allocate buffer is %d.\n",flag);	*/
}

#pragma mark public methods
-(void)start
{
	if(!self.isRunning){
		AudioOutputUnitStart(audioUnit_);
        self.isRunning = YES;
	}
}
-(void)stop
{
	if(self.isRunning) {
		AudioOutputUnitStop(audioUnit_);
		self.isRunning = NO;
	}
}
@end
