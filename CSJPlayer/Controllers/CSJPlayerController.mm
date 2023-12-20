//
//  InfoViewControllerForFFmpeg.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/21.
//

#import "CSJPlayerController.h"

#include "CSJPlayerCore.hpp"
#include "CSJVideoData.hpp"
#include "CSJAudioData.hpp"
#include "CSJVideoInformation.hpp"

#import "CSJRenderTools.h"
#import "CSJAUPlayer.h"
#import "CSJCommomTools.h"
#import "CSJAVFoundDecoder.h"

#import "Masonry.h"
#import "CSJMediaInfoView.h"
#import "CSJGLRenderView.h"
#import "CSJHorPrograssBar.h"

@interface CSJPlayerController () <CSJRenderDelegate, CSJAudioRenderDelegate> {
    CSJPlayerCore *player;
}

@property (nonatomic, strong) NSButton    *dismissBtn;
@property (nonatomic, strong) NSButton    *openVideoBtn;
@property (nonatomic, strong) NSButton    *closeVideoBtn;
@property (nonatomic, strong) NSButton    *infoBtn;

@property (nonatomic, strong) NSButton    *playBtn;
@property (nonatomic, strong) NSButton    *stopBtn;
@property (nonatomic, strong) NSButton    *pauseBtn;
@property (nonatomic, strong) NSTextField *timeField;

@property (nonatomic, strong) CSJMediaInfoView  *mediaInfoView;
@property (nonatomic, strong) NSView            *playerView;
@property (nonatomic, strong) CSJGLRenderView   *renderView;
@property (nonatomic, strong) CSJHorPrograssBar *prograssBar;

@property (nonatomic, strong) CSJAUPlayer       *audioPlayer;
@property (nonatomic, assign) NSInteger         duration;       // 媒体文件的总时长;
@property (nonatomic, assign) NSInteger         pastDuration;   // 已经播放的时长;
@property (nonatomic, assign) BOOL              isSeek;         // 是否在seek中，也就是鼠标拖动进度条的状态;

@property (nonatomic, strong) NSTimer           *timer;


@end

@implementation CSJPlayerController

- (instancetype)init {
    if (self = [super init]) {
        
        [self initUI];
        
        [self initPlayerCore];
    }
    
    return self;
}

- (void)dealloc {
    if (player) {
        delete player;
        player = nullptr;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [self clearPlayingStatus];
}

// 清理播放状态，在播放过程中，退出应用、退出页面、选择了播放其他文件等
- (void)clearPlayingStatus {
    if (player->isPlaying() || player->isPause()) {
        [self.audioPlayer stop];
        [self.renderView stopRender];
        
        player->stop();
    }
}

- (void)initUI {
    [self.view addSubview:self.dismissBtn];
    [self.dismissBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(10);
        make.right.mas_equalTo(-10);
        make.size.mas_equalTo(CGSizeMake(80, 20));
    }];
    
    [self.view addSubview:self.openVideoBtn];
    [self.openVideoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.dismissBtn.mas_bottom).offset(10);
        make.left.equalTo(self.dismissBtn);
        make.size.equalTo(self.dismissBtn);
    }];
    
    [self.view addSubview:self.closeVideoBtn];
    [self.closeVideoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.openVideoBtn);
    }];
    
    [self.view addSubview:self.infoBtn];
    [self.infoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.openVideoBtn.mas_bottom).offset(10);
        make.left.equalTo(self.openVideoBtn);
        make.size.equalTo(self.openVideoBtn);
    }];
    
    [self.view addSubview:self.mediaInfoView];
    self.mediaInfoView.hidden = YES;
    [self.mediaInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.mas_equalTo(10);
        make.size.mas_equalTo(CGSizeMake(400, 500));
    }];
    
    [self.view addSubview:self.playerView];
    [self.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.mas_equalTo(10);
        make.right.mas_equalTo(-100);
        make.bottom.mas_equalTo(-5);
    }];
    
    [self.playerView addSubview:self.renderView];
    [self.renderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(850, 478));
    }];
    
    [self.playerView addSubview:self.playBtn];
    [self.playerView addSubview:self.pauseBtn];
    [self.playerView addSubview:self.stopBtn];
    
    [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.top.equalTo(self.renderView.mas_bottom).offset(18);
        make.size.mas_equalTo(CGSizeMake(60, 20));
    }];
    
    [self.pauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.playBtn);
    }];
    
    [self.stopBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playBtn.mas_right).offset(5);
        make.top.equalTo(self.playBtn);
        make.size.equalTo(self.playBtn);
    }];
    
    [self.playerView addSubview:self.timeField];
    [self.timeField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.renderView.mas_bottom).offset(2);
        make.right.mas_offset(-2);
        make.height.mas_equalTo(15);
    }];
    
    [self.playerView addSubview:self.prograssBar];
    [self.prograssBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(0);
        make.right.equalTo(self.timeField.mas_left).offset(-2);
        make.top.equalTo(self.timeField);
        make.height.mas_equalTo(15);
    }];
    
    [self setBackgroundColor:[NSColor grayColor]];
}

- (void)initPlayerCore {
    player = new CSJPlayerCore();
    
    if (self.audioPlayer) {
        
    }
    
    CSJAVFoundDecoder *avDecoder = [[CSJAVFoundDecoder alloc] initWithUrl:nil];
    [avDecoder outputTrackInfos];
}

- (NSURL *)chooseMeidaFile {
    
    NSURL *resUrl = nil;
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    
    NSInteger finded = [panel runModal];
    if (finded == NSFileHandlingPanelOKButton) {
        resUrl = [panel URLs][0];
    }
    
    return resUrl;
}

- (void)onOpenVideo {
    if (!player) {
        return ;
    }
    
    NSURL *url = [self chooseMeidaFile];//[[NSBundle mainBundle] URLForResource:@"nightAskDay" withExtension:@"mp4"];
    if (!url) {
        NSLog(@"No file selected!");
        return ;
    }
    NSString* outputStr = url.path;
    const char *filePath = [outputStr UTF8String];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if (![fileMgr fileExistsAtPath:outputStr]) {
        NSLog(@"the output file isn't exist!");
        return ;
    }
    
    bool success = player->openVideoWithPath(filePath);
    if (!success) {
        return ;
    }
    
    [self.mediaInfoView loadMediaInfo:player->getMediaInfo()];
    
    self.playBtn.enabled = YES;
    self.openVideoBtn.hidden = YES;
    self.closeVideoBtn.hidden = NO;
    
    _duration = player->getMediaInfo()->getDuration();
    NSString *timeStr = [CSJTimeTools time_HHMMSSFromSecs:_duration];
    self.timeField.stringValue = timeStr;
    
    //[self startTimer];
}

// 用来测试进度条的;
- (void)startTimer {
    __weak typeof(self) weakself = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (weakself.isSeek) {
            return ;
        }
        weakself.pastDuration++;
        CGFloat pastRate = weakself.pastDuration / (weakself.duration * 1.0);
        [weakself.prograssBar updateCursorPos:pastRate];
        
        NSString *restTimeStr = [CSJTimeTools time_HHMMSSFromSecs:(weakself.duration - weakself.pastDuration)];
        weakself.timeField.stringValue = restTimeStr;
        
        if (pastRate == 1) {
            [weakself timeOut];
        }
    }];
}

- (void)timeOut {
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.pastDuration = 0;
}

- (void)onCloseVideo {
    if (!player) {
        return ;
    }
    
    if (player->isPlaying() || player->isPause()) {
        [self stopPlay];
    }
    
    self.openVideoBtn.hidden = NO;
    self.closeVideoBtn.hidden = YES;
}

- (void)infoBtnClicked {
    self.playerView.hidden = !self.playerView.hidden;
    self.mediaInfoView.hidden = !self.mediaInfoView.hidden;
}

- (void)startPlay {
    if (!player->isReady()) {
        NSLog(@"[%@] player isn't ready to play!", NSStringFromClass([self class]));
    }

    player->start();
    [self.audioPlayer start];
    [self.renderView startRedner];
    self.playBtn.hidden = YES;
    self.pauseBtn.hidden = NO;
    self.stopBtn.enabled = YES;
}

- (void)pausePlay {    
    if (player->isPause()) {
        [self resumePlay];
        return ;
    }
    
    // 使用系统的渲染回调时，暂停使用stopRender就可以
    //[self.renderView stopRender];
    // 使用自己管理的渲染线程时，暂定只能使用pauseRender
    [self.renderView pauseRender];
    [self.audioPlayer pause];
    player->pause();
    self.pauseBtn.title = @"继续";
}

- (void)resumePlay {
    // 使用系统的渲染回调时，继续使用startRender就可以
    //[self.renderView startRedner];
    // 使用自己管理的渲染线程时，暂定只能使用resumeRender
    [self.renderView resumeRender];
    [self.audioPlayer resume];
    player->resume();
    
    self.pauseBtn.title = @"暂停";
}

- (void)stopPlay {
    // stop video render;
    [self.renderView stopRender];
    // TODO: stop audio player;
    
    // stop the player core;
    player->stop();
    
    self.playBtn.hidden = NO;
    self.pauseBtn.hidden = YES;
    self.pauseBtn.enabled = NO;
    self.pauseBtn.title = @"暂停";
    
    self.stopBtn.enabled = NO;
}

- (void)btnClicked:(NSButton *)sender {
    if (sender == self.dismissBtn) {
        [self dismissController:nil];
    } else if (sender == self.openVideoBtn) {
        [self onOpenVideo];
    } else if (sender == self.closeVideoBtn) {
        [self onCloseVideo];
    } else if (sender == self.infoBtn) {
        [self infoBtnClicked];
    } else if (sender == self.playBtn) {
        [self startPlay];
    } else if (sender == self.pauseBtn) {
        [self pausePlay];
    } else if (sender == self.stopBtn) {
        [self stopPlay];
    }
}

- (void)seekOpearte:(CGFloat)rate {
    _pastDuration = _duration * rate;
    NSInteger restTime = _duration - _pastDuration;
    NSString *restTimeStr = [CSJTimeTools time_HHMMSSFromSecs:restTime];
    self.timeField.stringValue = restTimeStr;
    
    // playcore execute seek.
    player->seekToTime(_pastDuration);
    
    // renderView render current video frame after seeking.
    [self.renderView renderSeekVideo];
    
    // TODO: 进度条拖动中
    // 1.根据rate计算当前的时间，调用player的seek方法
    // 2.每一次seek之后，获取当前的视频帧，渲染出来
}

- (void)changeSeekStatus:(BOOL)isSeek {
    if (isSeek) {
        [self pausePlay];
    } else {
        // TODO: 拖动结束之后，需要清空当前的音视频数据队列，从结束时间点开始解码播放
        [self resumePlay];
    }
    
    self.isSeek = isSeek;
}

#pragma mark - overrides from CSJRenderDelegate;
- (CSJVideoData *)getRenderImageData {
    int isFinished = 0;
    CSJVideoData *videoData = player->getRenderVideoData(isFinished);
    
    // play to the eof;
    if (isFinished == 1) {
        [self.renderView stopRender];
    }
    
    return videoData;
}

- (CSJVideoData *)getSeekImageData {
    CSJVideoData *videoData = player->getSeekVideoData();
    return std::move(videoData);
}

- (void)updateRestTime:(double)curTime {
    self.pastDuration = curTime;
    CGFloat pastRate = self.pastDuration / (self.duration * 1.0);
    [self.prograssBar updateCursorPos:pastRate];
    
    NSString *restTimeStr = [CSJTimeTools time_HHMMSSFromSecs:(self.duration - self.pastDuration)];
    self.timeField.stringValue = restTimeStr;
}

#pragma mark - overrides from CSJAudioRenderDelegate;
- (CSJAudioData *)getRenderAudioData {
    int isFinished = 0;
    CSJAudioData *audioData = player->getAudioData(isFinished);
    
    // play to the eof;
    if (isFinished == 1) {
        [self.audioPlayer stop];
    }
    
    return audioData;
}

#pragma mark - getters;
- (CSJAUPlayer *)audioPlayer {
    if (!_audioPlayer) {
        _audioPlayer = [[CSJAUPlayer alloc] initWithOnlyOutput];
        _audioPlayer.audioDelegate = self;
    }
    
    return _audioPlayer;
}

- (NSButton *)dismissBtn {
    if (!_dismissBtn) {
        _dismissBtn = [NSButton buttonWithTitle:@"主页" target:self action:@selector(btnClicked:)];
    }
    
    return _dismissBtn;
}

- (NSButton *)openVideoBtn {
    if (!_openVideoBtn) {
        _openVideoBtn = [NSButton buttonWithTitle:@"打开文件" target:self action:@selector(btnClicked:)];
    }
    
    return _openVideoBtn;
}

- (NSButton *)closeVideoBtn {
    if (!_closeVideoBtn) {
        _closeVideoBtn = [NSButton buttonWithTitle:@"关闭文件" target:self action:@selector(btnClicked:)];
        _closeVideoBtn.hidden = YES;
    }
    
    return _closeVideoBtn;
}

- (NSButton *)infoBtn {
    if (!_infoBtn) {
        _infoBtn = [NSButton buttonWithTitle:@"文件详情" target:self action:@selector(btnClicked:)];
    }
    
    return _infoBtn;
}

- (CSJGLRenderView *)renderView {
    if (!_renderView) {
        _renderView = [[CSJGLRenderView alloc] initWithImageType:CSJRenderImageType_YUV420];
        _renderView.renderDelegate = self;
    }
    
    return _renderView;
}

- (CSJMediaInfoView *)mediaInfoView {
    if (!_mediaInfoView) {
        _mediaInfoView = [CSJMediaInfoView new];
        
        CALayer *viewLayer = [CALayer layer];
        [_mediaInfoView setWantsLayer:YES];
        [_mediaInfoView setLayer:viewLayer];
        _mediaInfoView.layer.backgroundColor = [NSColor yellowColor].CGColor;
        [_mediaInfoView setNeedsDisplay:YES];
        
        _mediaInfoView.layer.cornerRadius = 6;
        _mediaInfoView.layer.masksToBounds = YES;
    }
    
    return _mediaInfoView;
}

- (NSView *)playerView {
    if (!_playerView) {
        _playerView = [[NSView alloc] init];
        
        CALayer *viewLayer = [CALayer layer];
        NSView *backgroundView= _playerView;
        [backgroundView setWantsLayer:YES];
        [backgroundView setLayer:viewLayer];
        backgroundView.layer.backgroundColor = [NSColor whiteColor].CGColor;
        [backgroundView setNeedsDisplay:YES];
    }
    
    return _playerView;
}

- (NSButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [NSButton buttonWithTitle:@"播放" target:self action:@selector(btnClicked:)];
        _playBtn.enabled = NO;
    }
    
    return _playBtn;
}

- (NSButton *)stopBtn {
    if (!_stopBtn) {
        _stopBtn = [NSButton buttonWithTitle:@"停止" target:self action:@selector(btnClicked:)];
        _stopBtn.enabled = NO;
    }
    
    return _stopBtn;
}

- (NSButton *)pauseBtn {
    if (!_pauseBtn) {
        _pauseBtn = [NSButton buttonWithTitle:@"暂停" target:self action:@selector(btnClicked:)];
        _pauseBtn.hidden = YES;
    }
    
    return _pauseBtn;
}

- (NSTextField *)timeField {
    if (!_timeField) {
        _timeField = [[NSTextField alloc] init];
        _timeField.backgroundColor = [NSColor grayColor];
        _timeField.textColor = [NSColor whiteColor];
        _timeField.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _timeField.alignment = NSTextAlignmentRight;
        _timeField.editable = NO;
        _timeField.layer.masksToBounds = YES;
        _timeField.stringValue = @"00:00";
        _timeField.bordered = false;
    }
    
    return _timeField;
}

- (CSJHorPrograssBar *)prograssBar {
    if (!_prograssBar) {
        _prograssBar = [[CSJHorPrograssBar alloc] initWithFrame:NSZeroRect];
        __weak typeof(self) weakself = self;
        _prograssBar.updateTimeBlock = ^(CGFloat rate) {
            [weakself seekOpearte:rate];
        };
        
        _prograssBar.notifySeekBlock = ^(BOOL isSeek) {
            [weakself changeSeekStatus:isSeek];
        };
    }
    
    return _prograssBar;
}

@end
