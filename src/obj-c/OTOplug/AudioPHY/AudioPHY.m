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
    bool _shouldResume;
}

@property(nonatomic, assign) float outputVolume;
@property(nonatomic, assign) BOOL isHeadsetIn;
@property(nonatomic, assign) BOOL isMicAvailable;
@property(nonatomic, assign) BOOL isInterrupted;
@property(nonatomic, assign) BOOL isRunning;
@end

@implementation AudioPHY
#pragma mark - Properties
@synthesize delegate;
@synthesize modem;
@synthesize isMicAvailable;
@synthesize isRunning;

@dynamic outputVolume;
@dynamic isHeadsetIn;
@dynamic isInterrupted;

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
	
	AudioUnitUninitialize(audioUnit_);
	AudioComponentInstanceDispose(audioUnit_);

    // 通知の登録解除
    [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"outputVolume"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
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

#pragma mark - private methods
-(void)sessionDidInterrupt:(NSNotification *)notification
{
    NSError *error;
    
    AVAudioSessionInterruptionType intrruptionType = [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    switch (intrruptionType) {
        case AVAudioSessionInterruptionTypeBegan:
//            NSLog(@"Begin AudioSession interruption.");
            self.isInterrupted = YES;
            _shouldResume = self.isRunning;
            [self stop];
            break;

        default:
        case AVAudioSessionInterruptionTypeEnded:
//            NSLog(@"End AudioSession interruption.");
            self.isInterrupted = NO;
            [[AVAudioSession sharedInstance] setActive:true error:&error];
            [OTOplugUtility checkNSError:@"setActive:error:" error:error];
            if(_shouldResume) {
                [self start];
            }
            break;
    }
}

-(void)sessionDidRouteChange:(NSNotification *)notification
{
    [self checkAndRequestHeadsetInput];
}


// ヘッドセット入力が利用可能かを確認する。利用できるなら、その入力に切り替える。
// isHeadsetIn プロパティを、状況をあらわすように値を設定する。
-(void)checkAndRequestHeadsetInput
{
    NSError *error;
    bool result;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];

    // 入力を設定
    result = false;
    for(AVAudioSessionPortDescription *portDesc in session.currentRoute.inputs) {
//        NSLog(@"input: name:%@, type:%@.", portDesc.portName, portDesc.portType);
        if([portDesc.portType isEqualToString:AVAudioSessionPortLineIn] || [portDesc.portType isEqualToString:AVAudioSessionPortHeadsetMic]) {
            result = true;
            // 入力設定
            [session setPreferredInput:portDesc error:&error];
            [OTOplugUtility checkNSError:@"setPreferredInput:error:" error:error];
        }
    }
    self.isMicAvailable = result;
    
    // 出力を設定
    result = false;
    for(AVAudioSessionPortDescription *portDesc in session.currentRoute.outputs) {
//        NSLog(@"output: name:%@, type:%@.", portDesc.portName, portDesc.portType);
        if([portDesc.portType isEqualToString:AVAudioSessionPortLineOut] || [portDesc.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            result = true;
        }
    }
    self.isHeadsetIn = result;
}

-(void)prepareAudioSession:(float)samplingRate audioBufferSize:(int)audioBufferSize
{
    NSError *error;
    bool result;
    
    // Audio sessionを取得
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    // Audio Session Categoryを設定
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [OTOplugUtility checkNSError:@"setCategory:" error:error];
    
    // モードセット
    result = [session setMode:AVAudioSessionModeMeasurement error:&error];
    [OTOplugUtility checkNSError:@"setMode:error:" error:error];
    if( ! result ) {
        NSLog(@"audio session mode was not accepted.");
    }
    
    // ハードウェアサンプリング・レートを設定する
    result =[session setPreferredSampleRate:samplingRate error:&error];
    [OTOplugUtility checkNSError:@"setPreferredHardwareSampleRate:error:" error:error];
    if( ! result ) {
        NSLog(@"reqested hardware sampling rate was not accepted. reqested sampling rate: %f", samplingRate);
    }
    
    // オーディオバッファサイズを指定します。時間で指定します。
    NSTimeInterval duration = audioBufferSize / samplingRate;
    result = [session setPreferredIOBufferDuration:duration error:&error];
    [OTOplugUtility checkNSError:@"setPreferredIOBufferDuration:error:" error:error];
    if( ! result ) {
        NSLog(@"reqested buffer size hardware sampling rate was not accepted.");
    }

    // AudioSessionをアクティベート
    result = [session setActive:YES error:&error];
    [OTOplugUtility checkNSError:@"setActive:error:" error:error];
    if( ! result ) {
        NSLog(@"session activation not accepted.");
    }
/*
#if TARGET_IPHONE_SIMULATOR
    self.isMicAvailable = true;
	self.isHeadsetIn    = true;
#else // TARGET_IOS_IPHONE
    [self checkAndRequestHeadsetInput];
#endif
*/
    [self checkAndRequestHeadsetInput];
    
    // KVOを登録、プロパティの初期値を設定。
    self.outputVolume = session.outputVolume;
    [session addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
    
    // audio session の interupt notification を登録
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidInterrupt:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
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

#pragma KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    NSLog(@"%s %@.", __PRETTY_FUNCTION__, keyPath);
    if( [keyPath isEqualToString:@"outputVolume"]) {
        self.outputVolume = [AVAudioSession sharedInstance].outputVolume;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
