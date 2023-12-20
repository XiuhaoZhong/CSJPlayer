//
//  CSJMediaRecordingVC.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/7/5.
//

#import "CSJMediaRecordingVC.h"

#import <AVFoundation/AVFoundation.h>

#import "CSJCamPreviewView.h"
#import "NSView+UIView_Custom.h"
#import "Masonry.h"
#import "CSJFilterManager.h"

#import <GPUImage/GPUImage.h>
#import <GPUImage/GPUImageAVCamera.h>
#import <GPUImage/GPUImageVignetteFilter.h>

@interface CSJMediaRecordingVC () <AVCaptureVideoDataOutputSampleBufferDelegate,
                                   AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) NSArray *videoDevices;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (nonatomic, strong) NSArray *audioDevices;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

@property (nonatomic, assign) BOOL isRunning;                      /* 是否正在工作中 */
@property (nonatomic, assign) BOOL cameraAuth;                     /* 是否获得摄像头权限 */
@property (nonatomic, assign) BOOL microAuth;                      /* 时候获取麦克风权限 */

@property (nonatomic, strong) NSButton *startCaptureBtn;           /* 开始录制Btn */
@property (nonatomic, strong) NSButton *closeCaptureBtn;           /* 停止录制Btn */
@property (nonatomic, strong) NSButton *photoBtn;                  /* 拍照Btn */

@property (nonatomic, strong) NSPopUpButton *videoDevicePopBtn;    /* 摄像头复选框 */
@property (nonatomic, strong) NSPopUpButton *audioDevicePopBtn;    /* 麦克风复选框 */
@property (nonatomic, assign) NSInteger     curCameraIndex;
@property (nonatomic, assign) NSInteger     curMicrophoneIndex;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) CSJCamPreviewView *previewView;
@property (nonatomic, strong) AVCaptureSession  *mediaSession;
@property (nonatomic, strong) dispatch_queue_t  mediaSessionQueue;  /* 与设备、采集交互的队列 */

@property (nonatomic, strong) NSView           *imageBgView;        /* 预览的背景 */
@property (nonatomic, strong) GPUImageView     *gpuImageView;       /* 视频预览View */
@property (nonatomic, strong) GPUImageAVCamera *gpuCamera;          /* 音视频采集 */

@property (nonatomic, strong) CSJFilterManager *filterMgr;          /* 滤镜管理 */

@end

@implementation CSJMediaRecordingVC

- (instancetype)init {
    if (self = [super init]) {
        [self initUI];

        [self initMediaEnv];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
}

- (void)initUI {
    //[self.view addSubview:self.previewView];
    [self.view addSubview:self.imageBgView];
    //[self.view addSubview:self.gpuImageView];
    [self.view addSubview:self.videoDevicePopBtn];
    [self.view addSubview:self.audioDevicePopBtn];
    [self.view addSubview:self.startCaptureBtn];
    [self.view addSubview:self.photoBtn];
    [self.view addSubview:self.closeCaptureBtn];
    [self.view addSubview:self.filterMgr.contentView];
    
    [self.imageBgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.mas_equalTo(10);
        make.right.mas_equalTo(-150);
        make.bottom.mas_equalTo(-10);
    }];
    
    [self.videoDevicePopBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.top.mas_equalTo(10);
        make.width.mas_equalTo(CGSizeMake(120, 20));
    }];
    
    [self.audioDevicePopBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.top.equalTo(self.videoDevicePopBtn.mas_bottom).offset(5);
        make.width.mas_equalTo(CGSizeMake(120, 20));
    }];
    
    [self.startCaptureBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.top.equalTo(self.audioDevicePopBtn.mas_bottom).offset(5);
        make.width.mas_equalTo(CGSizeMake(80, 20));
    }];
    
    [self.closeCaptureBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.top.equalTo(self.startCaptureBtn.mas_bottom).offset(5);
        make.width.mas_equalTo(CGSizeMake(80, 20));
    }];
    
    [self.photoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.top.equalTo(self.closeCaptureBtn.mas_bottom).offset(5);
        make.width.mas_equalTo(CGSizeMake(80, 20));
    }];
    
    [self.filterMgr.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.bottom.right.equalTo(self.imageBgView);
        make.height.mas_equalTo(75);
    }];
    
    self.closeCaptureBtn.enabled = NO;
    self.photoBtn.enabled = NO;
    
    [self setBackgroundColor:[NSColor whiteColor]];
}

#pragma mark - private functions
- (void)initMediaEnv {
    [self getDevices];
    [self updateDevicePop];
    
    self.mediaSession = [[AVCaptureSession alloc] init];
    self.previewView.captureSession = self.mediaSession;
    self.mediaSessionQueue = dispatch_queue_create("csj.mediasession.com", DISPATCH_QUEUE_SERIAL);
    
    if ([self CheckVideoCaptureAuth]) {
        /* 配置摄像头 */
        [self configureSession];
    }
}

- (void)getDevices {
    NSArray *cameraTypeArray = @[AVCaptureDeviceTypeBuiltInWideAngleCamera];
    AVCaptureDeviceDiscoverySession *videoDeviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:cameraTypeArray mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    
    if (videoDeviceSession.devices.count > 0) {
        self.videoDevices = videoDeviceSession.devices;
    } else {
        NSLog(@"There are no cameras!");
    }
    
    NSArray *macrophoneTypeArr = @[AVCaptureDeviceTypeBuiltInMicrophone];
    AVCaptureDeviceDiscoverySession *audioDeviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:macrophoneTypeArr mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified];
    //  AVCaptureDevicePositionFront
    
    if (audioDeviceSession.devices.count > 0) {
        self.audioDevices = audioDeviceSession.devices;
    } else {
        NSLog(@"There are no macrophones!");
    }
}

- (void)updateDevicePop {
    NSMutableArray *videoDeviceArr = [NSMutableArray array];
    for (int i = 0; i < self.videoDevices.count; i++) {
        AVCaptureDevice *device = self.videoDevices[i];
        [videoDeviceArr addObject:device.localizedName];
    }
    
    [self.videoDevicePopBtn addItemsWithTitles:videoDeviceArr];
    _curCameraIndex = 0;
    [self.videoDevicePopBtn selectItemAtIndex:_curCameraIndex];
    
    NSMutableArray *audioDeviceArr = [NSMutableArray array];
    for (int i = 0; i < self.audioDevices.count; i++) {
        AVCaptureDevice *device = self.audioDevices[i];
        [audioDeviceArr addObject:device.localizedName];
    }
    [self.audioDevicePopBtn addItemsWithTitles:audioDeviceArr];
    _curMicrophoneIndex = 0;
    [self.audioDevicePopBtn selectItemAtIndex:_curMicrophoneIndex];
    
}

#pragma mark - Btn responses;
- (void)btnClicked:(NSButton *)sender {
    if (sender == self.startCaptureBtn) {
        /* 开始录制 */
        [self startCapture];
    } else if (sender == self.closeCaptureBtn) {
        /* 结束录制 */
        [self stopCapture];
    } else if (sender == self.photoBtn) {
        /* 拍照 */
        [self takePhoto];
    }
}

- (void)startCapture {
//    dispatch_async(self.mediaSessionQueue, ^{
//        if (!self.isRunning) {
//            [self.mediaSession startRunning];
//            self.isRunning = YES;
//        }
//    });
    [self.gpuCamera startCameraCapture];
    self.isRunning = YES;
    self.gpuImageView.hidden = NO;
    
    self.closeCaptureBtn.enabled = YES;
    self.photoBtn.enabled = YES;
    self.startCaptureBtn.enabled = NO;
}

- (void)stopCapture {
//    dispatch_async(self.mediaSessionQueue, ^{
//        if (self.isRunning) {
//            [self.mediaSession stopRunning];
//            self.isRunning = NO;
//        }
//    });
    
    [self.gpuCamera stopCameraCapture];
    self.isRunning = NO;
    self.gpuImageView.hidden = YES;
    
    self.startCaptureBtn.enabled = YES;
    self.closeCaptureBtn.enabled = NO;
    self.photoBtn.enabled = NO;
}

- (void)takePhoto {
    
}

/* 选择一个摄像头 */
- (void)selectedCamera:(NSPopUpButton *)btn {
    if (btn.indexOfSelectedItem == _curCameraIndex) {
        NSLog(@"the selected is current camera!");
        return ;
    } else {
        _curCameraIndex = btn.indexOfSelectedItem;
        NSLog(@"switch a camera!");
    }
}

/* 选择一个麦克风 */
- (void)selectedMicrophone:(NSPopUpButton *)btn {
    if (btn.indexOfSelectedItem == _curMicrophoneIndex) {
        NSLog(@"the selected is current microphone!");
        return ;
    } else {
        _curMicrophoneIndex = btn.indexOfSelectedItem;
        NSLog(@"swicth a microphone!");
    }
}

#pragma mark - private funtions;
/* 确认摄像头使用权限 */
- (BOOL)CheckVideoCaptureAuth {
    AVAuthorizationStatus authState = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authState == AVAuthorizationStatusAuthorized) {
        self.cameraAuth = YES;
        NSLog(@"Camera is already authorized");
    } else if (authState == AVAuthorizationStatusNotDetermined) {
        dispatch_suspend(self.mediaSessionQueue);
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (!granted) {
                self.cameraAuth = NO;
            } else {
                self.cameraAuth = YES;
            }
            dispatch_resume(self.mediaSessionQueue);
        }];
    } else {
        self.cameraAuth = NO;
    }
    
    if (!self.cameraAuth) {
        return NO;
    }
    
    authState = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (authState == AVAuthorizationStatusAuthorized) {
        self.microAuth = YES;
        NSLog(@"Microphone is already authorized");
    } else if (authState == AVAuthorizationStatusNotDetermined) {
        dispatch_suspend(self.mediaSessionQueue);
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (!granted) {
                self.microAuth = NO;
            } else {
                self.microAuth = YES;
            }
            dispatch_resume(self.mediaSessionQueue);
        }];
    } else {
        self.microAuth = NO;
    }
    
    return self.cameraAuth || self.microAuth;
}

- (void)configureSession {
    [self.mediaSession beginConfiguration];
    
    //self.mediaSession.sessionPreset = AVCaptureSessionPresetPhoto;
    
    NSError *error = nil;
    /* 视频采集设置 */
    AVCaptureDeviceInput *inputDevice = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevices[0] error:&error];
    if (!inputDevice) {
        NSLog(@"Couldn't create a input video device: %@", error);
        [self.mediaSession commitConfiguration];
        return ;
    }
    
    if ([self.mediaSession canAddInput:inputDevice]) {
        [self.mediaSession addInput:inputDevice];
        NSLog(@"video capture device is added!");
    }
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    /* 设置输出格式为YUV420 */
    videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
                                                            forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    /* 丢弃延时帧 */
    videoOutput.alwaysDiscardsLateVideoFrames = YES;
    dispatch_queue_t videoQueue = dispatch_queue_create("csj.videocapture.com", DISPATCH_QUEUE_SERIAL);
    [videoOutput setSampleBufferDelegate:self queue:videoQueue];
    
    if ([self.mediaSession canAddOutput:videoOutput]) {
        [self.mediaSession addOutput:videoOutput];
        NSLog(@"video output is added!");
    }
    self.videoOutput = videoOutput;
    
    AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    /* macOS 上可能不需要设置视频方向，先注释掉 */
//    if ([videoConnection isVideoOrientationSupported]) {
//        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
//    }
    _videoConnection = videoConnection;
    
    /* 音频采集设置 */
    AVCaptureDeviceInput *inputAudioDevice = [AVCaptureDeviceInput deviceInputWithDevice:self.audioDevices[0] error:&error];
    if (!inputAudioDevice) {
        NSLog(@"Couldn't create a input audio device: %@", error);
    }
    if ([self.mediaSession canAddInput:inputAudioDevice]) {
        [self.mediaSession addInput:inputAudioDevice];
        NSLog(@"audio capture device is added!");
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
    
    AVAudioFormat *audioFormat = [[AVAudioFormat alloc] initWithCommonFormat:kAudioFormatLinearPCM sampleRate:48000 channels:2 interleaved:NO];
    
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
//    audioOutput.audioSettings = [NSDictionary dictionaryWithObjects:@[@"AVFormatIDKey",
//                                                                      @"AVSampleRateKey",
//                                                                      @"AVNumberOfChannelKey",
//                                                                      @"AVLinearPCMBitDepthKey",
//                                                                      @"AVLinearPCMIsNonInterleaved",
//                                                                      @"AVLinearPCMIsFloatKey"
//                                                                    ] forKeys:@[@(kAudioFormatLinearPCM),
//                                                                                @(48000),
//                                                                                @(2),
//                                                                                @(16),
//                                                                                @(YES),
//                                                                                @(YES)]];
    dispatch_queue_t audioQueue = dispatch_queue_create("csj.audiocapture.com", DISPATCH_QUEUE_SERIAL);
    [audioOutput setSampleBufferDelegate:self queue:audioQueue];
    
    if ([self.mediaSession canAddOutput:audioOutput]) {
        [self.mediaSession addOutput:audioOutput];
        NSLog(@"audio output is added!");
    }
    self.audioOutput = audioOutput;
    
//    AVCaptureConnection *audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
//    _audioConnection = audioConnection;
    
    [self.mediaSession commitConfiguration];
}

- (void)processVideoFrame:(CMSampleBufferRef)videoSample {
    
}

- (void)processAudioFrame:(CMSampleBufferRef)audioSample {
    
}

#pragma mark - overrides from AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//    if (connection == self.videoConnection) {
//        NSLog(@"received video data");
//    }
//
//    if (connection == self.audioConnection) {
//        NSLog(@"received audio data");
//    }
    
    if (output == self.audioOutput) {
        NSLog(@"received audio data");
    } else if (output == self.videoOutput) {
        NSLog(@"received video data");
    }
    
    
}

#pragma mark - getters;

- (NSButton *)startCaptureBtn {
    if (!_startCaptureBtn) {
        _startCaptureBtn = [NSButton buttonWithTitle:@"打开摄像头" target:self action:@selector(btnClicked:)];
    }
    
    return _startCaptureBtn;
}

- (NSButton *)closeCaptureBtn {
    if (!_closeCaptureBtn) {
        _closeCaptureBtn = [NSButton buttonWithTitle:@"关闭摄像头" target:self action:@selector(btnClicked:)];
    }
    
    return _closeCaptureBtn;
}

- (NSButton *)photoBtn {
    if (!_photoBtn) {
        _photoBtn = [NSButton buttonWithTitle:@"拍照" target:self action:@selector(btnClicked:)];
    }
    
    return _photoBtn;
}

- (CSJCamPreviewView *)previewView {
    if (!_previewView) {
        _previewView = [[CSJCamPreviewView alloc] init];
        [_previewView setBackgroundColor:[NSColor blackColor]];
    }
    
    return _previewView;
}

- (NSPopUpButton *)videoDevicePopBtn {
    if (!_videoDevicePopBtn) {
        _videoDevicePopBtn = [[NSPopUpButton alloc] init];
        _videoDevicePopBtn.preferredEdge = NSRectEdgeMaxY;
        _videoDevicePopBtn.pullsDown = NO;
        _videoDevicePopBtn.target = self;
        _videoDevicePopBtn.action = @selector(selectedCamera:);
    }
    
    return _videoDevicePopBtn;
}

- (NSPopUpButton *)audioDevicePopBtn {
    if (!_audioDevicePopBtn) {
        _audioDevicePopBtn = [[NSPopUpButton alloc] init];
        _audioDevicePopBtn.preferredEdge = NSRectEdgeMaxY;
        _audioDevicePopBtn.pullsDown = NO;
        _audioDevicePopBtn.target = self;
        _audioDevicePopBtn.action = @selector(selectedMicrophone:);
    }
    
    return _audioDevicePopBtn;
}

- (NSView *)imageBgView {
    if (!_imageBgView) {
        _imageBgView = [[NSView alloc] init];
        [_imageBgView setBackgroundColor:[NSColor blackColor]];
    }
    
    return _imageBgView;
}

- (GPUImageView *)gpuImageView {
    if (!_gpuImageView) {
        _gpuImageView = [[GPUImageView alloc] initWithFrame:CGRectMake(10, 10, 800, 520)];
    }
    
    return _gpuImageView;
}

- (GPUImageAVCamera *)gpuCamera {
    if (!_gpuCamera) {
        _gpuCamera = [[GPUImageAVCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraDevice:nil];
        //self.gpuImageView.frame = self.imageBgView.frame;
        _gpuImageView = [[GPUImageView alloc] initWithFrame:self.imageBgView.frame];
        [self.view addSubview:self.gpuImageView];
        [_gpuCamera addTarget:self.gpuImageView];
    }
    
    return _gpuCamera;
}

- (CSJFilterManager *)filterMgr {
    if (!_filterMgr) {
        _filterMgr = [[CSJFilterManager alloc] initWithFilterMode:0];
    }
    
    return _filterMgr;
}

@end
