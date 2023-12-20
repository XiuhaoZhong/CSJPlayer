//
//  CSJAUPlayer.h
//  OnlyPlayer
//
//  Created by zhongxiuhao on 2021/9/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

class CSJAudioData;
@protocol CSJAudioRenderDelegate <NSObject>

@required
- (CSJAudioData *)getRenderAudioData;
- (void)updateRestTime:(double)curTime;

@end

@interface CSJAUPlayer : NSObject

@property (nonatomic, weak) id<CSJAudioRenderDelegate> audioDelegate;

// 直接指定播放文件;
- (id)initWithFilePath:(NSString *)path;

// 读取文件，使用callback的方式播放;
- (instancetype)initBufWithPath:(NSString *)path;

- (instancetype)initWithOnlyOutput;

- (void)setPlayFile:(NSString *)filePath;

- (void)start;
- (void)pause;
- (void)resume;
- (void)stop;

- (BOOL)play;

@end

NS_ASSUME_NONNULL_END
