//
//  CSJOpenGLRender.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//#import "glad.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSJOpenGLRender : NSObject

@property (nonatomic, assign) GLuint defaultFBOName;

- (instancetype)initForYUV420;
- (instancetype)initForRGBARender;
- (void)resizeWithWidth:(GLuint)width height:(GLuint)height;
- (void)render;

- (void)setImage:(CVImageBufferRef)pixelBuffer;
- (void)presentYUVData:(NSData *)yuvData width:(int)width height:(int)height;
- (void)presenRGBAData:(NSData *)rgbaData width:(int)width height:(int)height;

@end

NS_ASSUME_NONNULL_END
