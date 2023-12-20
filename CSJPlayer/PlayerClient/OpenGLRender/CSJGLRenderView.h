//
//  CSJGLRenderView.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/25.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CVDisplayLink.h>

#include "CSJRenderTools.h"

NS_ASSUME_NONNULL_BEGIN
class CSJVideoData;
@protocol CSJRenderDelegate <NSObject>

@required
- (CSJVideoData *)getRenderImageData;
- (CSJVideoData *)getSeekImageData;

@end

@interface CSJGLRenderView : NSOpenGLView {
    CVDisplayLinkRef displayLink;
}

@property (nonatomic, weak) id<CSJRenderDelegate> renderDelegate;

- (instancetype)initWithImageType:(CSJRenderImageType)imageType;

- (void)startRedner;
- (void)pauseRender;
- (void)resumeRender;
- (void)stopRender;

- (void)renderSeekVideo;

- (void)setImage:(CVImageBufferRef)img;
- (void)presentImageData:(NSData *)imageData width:(CGFloat)width height:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
