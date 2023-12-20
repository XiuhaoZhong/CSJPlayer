//
//  CSJAUPlayer.m
//  OnlyPlayer
//
//  Created by zhongxiuhao on 2021/9/8.
//

#import "CSJAUPlayer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#include "CSJAudioData.hpp"

const uint32_t CONST_BUFFER_SIZE = 0x10000;
static OSStatus playCallbackFunc(void *inRefCon,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData);

@interface CSJAUPlayer ()

@property (nonatomic, strong) NSData *audioDataL;   // 左声道数据， 单声道时只使用左声道;
@property (nonatomic, strong) NSData *audioDataR;   // 右声道数据;
@property (nonatomic, assign) NSInteger channelNum; // 通道数;
@property (nonatomic, assign) NSInteger length;     // 数据总长度，
@property (nonatomic, assign) NSInteger curLen;     // 当前已播放的长度;
@property (nonatomic, assign) NSInteger readLen;    // 每次要读取的长度;

@end

@implementation CSJAUPlayer {
    AUGraph     mPlayerGraph;
    AUNode      mPlayerNode;
    AudioUnit   mPlayerUnit;
    AUNode      mSplitterNode;
    AudioUnit   mSplitterUnit;
    AUNode      mAccMixerNode;
    AudioUnit   mAccMixerUnit;
    AUNode      mVocalMixerNode;
    AudioUnit   mVocalMixerUnit;
    AUNode      mPlayerIONode;
    AudioUnit   mPlayerIOUnit;
    NSURL       *mPlayPath;
    
    AudioStreamBasicDescription outputFormat;
    
    AudioBufferList *bufList;
    ExtAudioFileRef extAudioFile;
    
    SInt64      readSize;   // 已读Frame数量;
    SInt64      totalSize;  // Frame总数量;
    
    AUNode    audio_play_node;
    AudioUnit audio_play_unit;
    
    CSJAudioData *audioData;
    
    FILE         *originFilel_;
}

#pragma mark - public functions;
- (instancetype)init {
    if (self = [super init]) {
       
    }
    
    return self;
}

- (id)initWithFilePath:(NSString *)path {
    if (self = [super init]) {
        mPlayPath = [NSURL URLWithString:path];
        
        return self;
    }
    
    return nil;
}

- (instancetype)initBufWithPath:(NSString *)path {
    if (self = [super init]) {
        
        mPlayPath = [NSURL URLWithString:path];
        
        //[self initSingleOutputGraph];
    }
    
    return self;
}

- (instancetype)initWithOnlyOutput {
    if (self = [super init]) {
        //[self initForOutput];
        [self initAudioUnit];
        
        originFilel_ = fopen("originl.pcm", "w+");
        if (!originFilel_) {
            NSLog(@" can't create music file!");
        }
    }
    
    return self;
}

- (BOOL)play {
    OSStatus status = AUGraphStart(mPlayerGraph);
    CheckStatus(status, @"couldn't start AUGraph", YES);
    
    return YES;
}

- (void)resume {
    [self start];
}

- (void)pause {
    [self stop];
}

- (void)stop {
//    Boolean isRunning = false;
//    OSStatus status = AUGraphIsRunning(mPlayerGraph, &isRunning);
//    if (isRunning) {
//        status = AUGraphStop(mPlayerGraph);
//        CheckStatus(status, @"couldn't stop AUGraph", YES);
//    }
    
    OSStatus status = AudioOutputUnitStop(audio_play_unit);
    CheckStatus(status, @"stop audio error!", YES);
}

#pragma mark - private functions;
- (void)initForOutput {
    OSStatus status = NewAUGraph(&mPlayerGraph);
    CheckStatus(status, @"Couldn't create a new AUGraph", YES);
    AudioComponentDescription acd;
    acd.componentType = kAudioUnitType_Output;
    acd.componentSubType = kAudioUnitSubType_DefaultOutput;
    acd.componentFlags = 0;
    acd.componentFlagsMask = 0;
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    status = AUGraphAddNode(mPlayerGraph, &acd, &audio_play_node);
    
    status = AUGraphOpen(mPlayerGraph);
    
    status = AUGraphNodeInfo(mPlayerGraph, audio_play_node, NULL, &audio_play_unit);
    
    UInt32 max_frame_per_slice = 4096;
    status = AudioUnitSetProperty(audio_play_unit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0,
                                  &max_frame_per_slice,
                                  sizeof(max_frame_per_slice));
    
    if (status != noErr) {
        
    }
    
    AudioStreamBasicDescription stereoStreamFormat;
    UInt32 bytesPerSample = sizeof(SInt16);
    bzero(&stereoStreamFormat, sizeof(stereoStreamFormat));
    stereoStreamFormat.mFormatID = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
    stereoStreamFormat.mBytesPerPacket = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket = 1;
    stereoStreamFormat.mChannelsPerFrame = 2;   // 立体声;
    stereoStreamFormat.mBitsPerChannel = 8 * bytesPerSample;
    stereoStreamFormat.mBytesPerFrame = bytesPerSample;
    stereoStreamFormat.mSampleRate = 48000;
    
    status = AudioUnitSetProperty(audio_play_unit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Input,
                                  0,
                                  &stereoStreamFormat,
                                  sizeof(stereoStreamFormat));
    if (status != noErr) {
        
    }

    AURenderCallbackStruct callback;
    //callback.inputProc = render_cb_lpcm;
    callback.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(audio_play_unit,
                                  kAudioUnitProperty_SetRenderCallback,
                                  kAudioUnitScope_Input,
                                  0,
                                  &callback,
                                  sizeof(AURenderCallbackStruct));
    
    if (status != noErr) {
        
    }
    
    status = AUGraphInitialize(mPlayerGraph);
    if (status != noErr) {

    }
}

- (void)initAudioUnit {
    OSStatus err = noErr;
    AudioComponentDescription desc = (AudioComponentDescription) {
        .componentType         = kAudioUnitType_Output,
        .componentSubType      = kAudioUnitSubType_DefaultOutput,
        .componentManufacturer = kAudioUnitManufacturer_Apple,
        .componentFlags        = 0,
        .componentFlagsMask    = 0,
    };

    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    if (comp == NULL) {
        return ;
    }

    err = AudioComponentInstanceNew(comp, &audio_play_unit);

    AudioStreamBasicDescription stereoStreamFormat;
    UInt32 bytesPerSample = sizeof(SInt16);
    bzero(&stereoStreamFormat, sizeof(stereoStreamFormat));
    stereoStreamFormat.mFormatID = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved;
    stereoStreamFormat.mBytesPerPacket = bytesPerSample;
    stereoStreamFormat.mFramesPerPacket = 1;
    stereoStreamFormat.mChannelsPerFrame = 2;   // 立体声;
    stereoStreamFormat.mBitsPerChannel = 8 * bytesPerSample;
    stereoStreamFormat.mBytesPerFrame = bytesPerSample;
    stereoStreamFormat.mSampleRate = 48000;

    err = AudioUnitSetProperty(audio_play_unit,
                               kAudioUnitProperty_StreamFormat,
                               kAudioUnitScope_Input,
                               0,
                               &stereoStreamFormat,
                               sizeof(stereoStreamFormat));

    AURenderCallbackStruct render_cb = (AURenderCallbackStruct) {
        .inputProc       = playCallbackFunc,
        .inputProcRefCon = (__bridge void *)self,
    };
    
    UInt32 max_frame_per_slice = 4096;
    err = AudioUnitSetProperty(audio_play_unit,
                               kAudioUnitProperty_MaximumFramesPerSlice,
                               kAudioUnitScope_Global,
                               0,
                               &max_frame_per_slice,
                               sizeof(max_frame_per_slice));

    err = AudioUnitSetProperty(audio_play_unit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input, 0, &render_cb,
                               sizeof(AURenderCallbackStruct));
    
    err = AudioUnitInitialize(audio_play_unit);
    if (err != noErr) {
        
    }
}

- (void)start {
    OSStatus status = AudioOutputUnitStart(audio_play_unit);
    //OSStatus status = AUGraphStart(mPlayerGraph);
    if (status != noErr) {
        NSLog(@"Audio unit start error!");
    }
}

- (void)fillAudioData:(AudioBufferList *)bufferList {
    if (_length == 0) {
        // get next audio data from delegate;
        if ([self.audioDelegate respondsToSelector:@selector(getRenderAudioData)]) {
            audioData = [self.audioDelegate getRenderAudioData];
        }
        
        if (!audioData) {
            for (NSInteger i = 0; i < bufferList->mNumberBuffers; i++) {
                memset(bufferList->mBuffers[i].mData, 0, bufferList->mBuffers[0].mDataByteSize);
            }
            return ;
        }
        
        _length = audioData->getSize();
        _channelNum = audioData->getChannels();
        _curLen = 0;
        
        // 只考虑单通道和双通道;
        _readLen = bufferList->mBuffers[0].mDataByteSize * _channelNum;
        
        // 更新播放进度条;
        double curTimeStamp = audioData->getTimeStamp();
        if ([self.audioDelegate respondsToSelector:@selector(updateRestTime:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.audioDelegate updateRestTime:curTimeStamp];
            });
        }
    }
    
    if (_length > 0) {
        NSInteger actualLen = _readLen > _length ? _length : _readLen;
        if (_channelNum == 2) {
            uint8_t *databegin = audioData->getData();
            uint8_t *left = (uint8_t *)bufferList->mBuffers[0].mData;
            uint8_t *right = (uint8_t *)bufferList->mBuffers[1].mData;
            memset(bufferList->mBuffers[1].mData, 0, bufferList->mBuffers[1].mDataByteSize);
            uint8_t *readP = (uint8_t *)(databegin + _curLen);
            for (int i = 0; i < actualLen / 2; i++) {
                if (i % 2 == 0) {
                    memcpy(left, readP, 2);
                    readP += 2;
                    left += 2;
                } else {
                    memcpy(right, readP, 2);
                    readP += 2;
                    right += 2;
                }
            }
            
            _curLen += actualLen;
        } else {
            bufferList->mBuffers->mNumberChannels = 1;
            memcpy(bufferList->mBuffers[0].mData, audioData->getData() + _curLen, actualLen);
            _curLen += actualLen;
        }
        
        _length -= _readLen;
    }
}

static void CheckStatus(OSStatus status, NSString *message, BOOL fatal) {
    if (status == noErr) {
        return ;
    }
    
    char fourCC[16];
    *(UInt32 *)fourCC = CFSwapInt32HostToBig(status);
    fourCC[4] = '\0';
    
    // isprintf用来判断字符是否可以print，如果是控制字符，则返回false;
    if (isprint(fourCC[0]) && isprint(fourCC[1]) && isprint(fourCC[2]) && isprint(fourCC[3])) {
        NSLog(@"%@: %s", message, fourCC);
    } else {
        NSLog(@"%@: %d", message, (int)status);
    }
    
    if (fatal) {
        exit(-1);
    }
}
@end

static OSStatus playCallbackFunc(void *inRefCon,
                          AudioUnitRenderActionFlags *ioActionFlags,
                          const AudioTimeStamp *inTimeStamp,
                          UInt32 inBusNumber,
                          UInt32 inNumberFrames,
                          AudioBufferList *ioData) {
    CSJAUPlayer *player = (__bridge CSJAUPlayer *)inRefCon;
    [player fillAudioData:ioData];
    return noErr;
}
