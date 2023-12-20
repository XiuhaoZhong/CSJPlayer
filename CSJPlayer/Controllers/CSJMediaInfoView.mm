//
//  CSJMideoInfoView.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/24.
//

#import "CSJMediaInfoView.h"

#import "CSJVideoInformation.hpp"
#import "Masonry.h"

@implementation CSJMediaInfoView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)loadMediaInfo:(CSJVideoInformation *)medioInfo {
    if (!medioInfo) {
        return ;
    }
    
    // 路径;
    NSTextField *pathKeyField = [self createKeyLabel];
    pathKeyField.stringValue = @"文件路径：";
    NSTextField *pathValueField = [self createKeyLabel];
    pathValueField.stringValue = [NSString stringWithUTF8String:medioInfo->getFilePath()->c_str()];
    
    // 格式;
    NSTextField *formatKeyField = [self createKeyLabel];
    formatKeyField.stringValue = @"格式：";
    NSTextField *formatValueField = [self createKeyLabel];
    formatValueField.stringValue = [NSString stringWithUTF8String:medioInfo->getFormat()->c_str()];
    
    // 时长;
    NSTextField *durationKeyField = [self createKeyLabel];
    durationKeyField.stringValue = @"时长：";
    NSTextField *durationValueField = [self createKeyLabel];
    durationValueField.stringValue = [NSString stringWithUTF8String:medioInfo->getDurationStr()->c_str()];

    // 帧率;
    NSTextField *frameRateKeyField = [self createKeyLabel];
    frameRateKeyField.stringValue = @"帧率：";
    NSTextField *frameRateValueField = [self createKeyLabel];
    frameRateValueField.stringValue = [NSString stringWithFormat:@"%@", @(medioInfo->getFrameRate())];
    
    // 平均比特率;
    NSTextField *videoAveBitRateKeyField = [self createKeyLabel];
    videoAveBitRateKeyField.stringValue = @"比特率：";
    NSTextField *videoAveBitRateValueField = [self createKeyLabel];
    videoAveBitRateValueField.stringValue = [NSString stringWithFormat:@"%@ Mbps", @(medioInfo->getVideoAverageBitRate())];
    
    // 宽;
    NSTextField *widthKeyField = [self createKeyLabel];
    widthKeyField.stringValue = @"宽：";
    NSTextField *widthValueField = [self createKeyLabel];
    widthValueField.stringValue = [NSString stringWithFormat:@"%@", @(medioInfo->getWidth())];
    
    // 高;
    NSTextField *heightKeyField = [self createKeyLabel];
    heightKeyField.stringValue = @"高：";
    NSTextField *heightValueField = [self createKeyLabel];
    heightValueField.stringValue = [NSString stringWithFormat:@"%@", @(medioInfo->getHeight())];
    
    // 数据长度;
    NSTextField *videoSizeKeyField = [self createKeyLabel];
    videoSizeKeyField.stringValue = @"数据长度：";
    NSTextField *videoSizeValueField = [self createKeyLabel];
    videoSizeValueField.stringValue = [NSString stringWithFormat:@"%@ MB", @(medioInfo->getVideoSize())];
    
    // 视频格式;
    NSTextField *videoFormatKeyField = [self createKeyLabel];
    videoFormatKeyField.stringValue = @"视频格式：";
    NSTextField *videoFormatValueField = [self createKeyLabel];
    videoFormatValueField.stringValue = [NSString stringWithUTF8String:medioInfo->getVideoFormat()->c_str()];
    
    // 音频格式;
    NSTextField *audioFormatKeyField = [self createKeyLabel];
    audioFormatKeyField.stringValue = @"音频格式：";
    NSTextField *audioFormatValueField = [self createKeyLabel];
    audioFormatValueField.stringValue = [NSString stringWithUTF8String:medioInfo->getAudioFormat()->c_str()];
    
    // 音频平均比特率;
    NSTextField *audioAveBitRateKeyField = [self createKeyLabel];
    audioAveBitRateKeyField.stringValue = @"比特率：";
    NSTextField *audioAveBitRateValueField = [self createKeyLabel];
    audioAveBitRateValueField.stringValue = [NSString stringWithFormat:@"%@ Kbps", @(medioInfo->getAudioAverageBitRate())];
    
    // 通道数;
    NSTextField *channelNumKeyField = [self createKeyLabel];
    channelNumKeyField.stringValue = @"通道数： ";
    NSTextField *channelNumValueField = [self createKeyLabel];
    channelNumValueField.stringValue = [NSString stringWithFormat:@"%@", @(medioInfo->getChannelNumbers())];
    
    // 采样率;
    NSTextField *sampleRateKeyField = [self createKeyLabel];
    sampleRateKeyField.stringValue = @"采样率： ";
    NSTextField *sampleRateValueField = [self createKeyLabel];
    sampleRateValueField.stringValue = [NSString stringWithFormat:@"%@", @(medioInfo->getSampleRate())];
    
    // 数据长度;
    NSTextField *audioSizeKeyField = [self createKeyLabel];
    audioSizeKeyField.stringValue = @"数据长度： ";
    NSTextField *audioSizeValueField = [self createKeyLabel];
    audioSizeValueField.stringValue = [NSString stringWithFormat:@"%@ KB", @(medioInfo->getAudioSize())];
    
    NSTextField *titleField = [self createKeyLabel];
    titleField.stringValue = @"整体数据";
    [self addSubview:titleField];
    [titleField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.mas_equalTo(10);
        make.size.mas_equalTo(CGSizeMake(60, 20));
    }];
    
    [self addSubview:pathKeyField];
    [pathKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleField);
        make.top.equalTo(titleField.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(70, 20));
    }];
    
    [self addSubview:pathValueField];
    [pathValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pathKeyField);
        make.left.equalTo(pathKeyField.mas_right).offset(5);
        make.height.mas_equalTo(20);
        make.right.mas_equalTo(-20);
    }];
    
    [self addSubview:formatKeyField];
    [formatKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleField);
        make.top.equalTo(pathKeyField.mas_bottom).offset(5);
        make.size.mas_equalTo(CGSizeMake(70, 20));
    }];
    
    [self addSubview:formatValueField];
    [formatValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(formatKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:durationKeyField];
    [durationKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleField);
        make.top.equalTo(formatKeyField.mas_bottom).offset(5);
        make.size.equalTo(formatKeyField);
    }];
    
    [self addSubview:durationValueField];
    [durationValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(pathValueField);
        make.top.equalTo(durationKeyField);
        make.size.equalTo(pathValueField);
    }];
    
    NSTextField *videoInfoView = [self createKeyLabel];
    videoInfoView.stringValue = @"视频数据";
    [self addSubview:videoInfoView];
    [videoInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(durationKeyField.mas_bottom).offset(10);
        make.left.equalTo(titleField);
        make.size.equalTo(titleField);
    }];
    
    [self addSubview:videoFormatKeyField];
    [videoFormatKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleField);
        make.top.equalTo(videoInfoView.mas_bottom).offset(5);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:videoFormatValueField];
    [videoFormatValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(videoFormatKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:frameRateKeyField];
    [frameRateKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(titleField);
        make.top.equalTo(videoFormatKeyField.mas_bottom).offset(5);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:frameRateValueField];
    [frameRateValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(pathValueField);
        make.top.equalTo(frameRateKeyField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:videoAveBitRateKeyField];
    [videoAveBitRateKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(frameRateKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:videoAveBitRateValueField];
    [videoAveBitRateValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(videoAveBitRateKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:widthKeyField];
    [widthKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(videoAveBitRateKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:widthValueField];
    [widthValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(widthKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:heightKeyField];
    [heightKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(widthKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:heightValueField];
    [heightValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(heightKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:videoSizeKeyField];
    [videoSizeKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(heightKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:videoSizeValueField];
    [videoSizeValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(videoSizeKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    NSTextField *audioInfoView = [self createKeyLabel];
    audioInfoView.stringValue = @"音频数据";
    [self addSubview:audioInfoView];
    [audioInfoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(videoSizeKeyField.mas_bottom).offset(10);
        make.left.equalTo(titleField);
        make.size.equalTo(titleField);
    }];
    
    [self addSubview:audioFormatKeyField];
    [audioFormatKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioInfoView.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:audioFormatValueField];
    [audioFormatValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioFormatKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:audioAveBitRateKeyField];
    [audioAveBitRateKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioFormatKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:audioAveBitRateValueField];
    [audioAveBitRateValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioAveBitRateKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:channelNumKeyField];
    [channelNumKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioAveBitRateKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:channelNumValueField];
    [channelNumValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(channelNumKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:sampleRateKeyField];
    [sampleRateKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(channelNumKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:sampleRateValueField];
    [sampleRateValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sampleRateKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
    [self addSubview:audioSizeKeyField];
    [audioSizeKeyField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sampleRateKeyField.mas_bottom).offset(5);
        make.left.equalTo(titleField);
        make.size.equalTo(pathKeyField);
    }];
    
    [self addSubview:audioSizeValueField];
    [audioSizeValueField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(audioSizeKeyField);
        make.left.equalTo(pathValueField);
        make.size.equalTo(pathValueField);
    }];
    
}

#pragma mark -- createLabels;

- (NSTextField *)createKeyLabel {
    NSTextField *keyField = [[NSTextField alloc] init];
    keyField.backgroundColor = [NSColor whiteColor];
    keyField.textColor = [NSColor blackColor];
    keyField.lineBreakMode = NSLineBreakByTruncatingMiddle;
    keyField.editable = NO;
    keyField.layer.cornerRadius = 8;
    keyField.layer.masksToBounds = YES;
    return keyField;
}



@end
