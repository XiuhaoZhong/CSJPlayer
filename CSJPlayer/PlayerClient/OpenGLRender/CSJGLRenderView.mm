//
//  CSJGLRenderView.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/25.
//

#import "CSJGLRenderView.h"

#import <mach/mach_time.h>

#import "CSJOpenGLRender.h"
#include "GLUtil.h"
#include "CSJVideoData.hpp"

@interface CSJGLRenderView () {
    CSJVideoData *videoData;
}

@property (nonatomic, assign) CSJRenderImageType renderType;
@property (nonatomic, strong) CSJOpenGLRender *render;

@property (nonatomic, strong) NSData *saveData;
@property (nonatomic, assign) NSInteger saveWidth;
@property (nonatomic, assign) NSInteger saveHeight;
@property (nonatomic, assign) double    imageTimeStamp;

@property (nonatomic, assign) int64_t  lastOutputTime;

@property (nonatomic, assign) BOOL isRender;
@property (nonatomic, assign) BOOL isBegin;

@property (nonatomic, strong) NSThread *renderThread;           // 渲染线程;
@property (nonatomic, assign) double   renderSleep;             // 渲染线程休眠时间;
@property (nonatomic, strong) dispatch_semaphore_t pauseSem;    // 暂停信号量;
@property (nonatomic, assign) BOOL     isPause;                 // 是否暂停;
@property (nonatomic, assign) BOOL     isStop;                  // 是否停止;

@end

@implementation CSJGLRenderView

static CVReturn myDisplayLinkDisplayCallback(CVDisplayLinkRef displayLink,
                                             const CVTimeStamp *now,
                                             const CVTimeStamp *outputTime,
                                             CVOptionFlags flagIn,
                                             CVOptionFlags *flagsOut,
                                             void *displayLinkContext) {
    CSJGLRenderView *glView = (__bridge CSJGLRenderView *)displayLinkContext;
    
    // TODO: 没有外接显示器和外接显示器的时候，此回调函数的频率是不一样的，所以最好的方式
    // 应该是根据屏幕回调的频率和视频的刷新频率来实际的更新的渲染频率，而不应该是以固定频率
    // 来处理。 2023-05-28
    
    int64_t diff = now->videoTime - glView.lastOutputTime;
    glView.lastOutputTime = now->videoTime;
    
    int64_t diff1 = outputTime->videoTime - glView.lastOutputTime;
    
    // TODO: 目前不清楚屏幕具体的刷新率，所以我按照每4调用更新一帧，每秒26帧左右;
    // TODO: 按照以上做法，屏幕的刷新率在100左右;
    CVReturn result = kCVReturnSuccess;
    if (glView.imageTimeStamp == 0.0 && !glView.isBegin) {
        result = [(__bridge CSJGLRenderView *)displayLinkContext getFrameForTime:outputTime];
    } else if (glView.imageTimeStamp == 1.0) {
        result = [(__bridge CSJGLRenderView *)displayLinkContext getFrameForTime:outputTime];
        glView.imageTimeStamp = 0.0;
    } else {
        glView.imageTimeStamp += 1.0;
    }
    glView.isBegin = YES;
    
    return result;
}

- (instancetype)initWithImageType:(CSJRenderImageType)imageType {
    if (self = [super init]) {
        _renderType = imageType;
        
        [self initUI];
    }
    
    return self;
}

- (instancetype)init {
    if (self = [super init]) {
        [self initUI];
    }
    
    return self;
}

- (void)dealloc {
    if (CVDisplayLinkIsRunning(displayLink)) {
        CVDisplayLinkStop(displayLink);
    }
    CVDisplayLinkRelease(displayLink);
}

- (void)initUI {
    NSOpenGLPixelFormatAttribute attrs[] = {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 24,
#if ESSENTIAL_GL_PRACTICES_SUPPORT_GL3
        NSOpenGLPFAOpenGLProfile,
        NSOpenGLProfileVersion3_2Core,
#endif
        0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    if (!pf) {
        NSLog(@"NO OpenGL pixel format");
    }
    
    NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:nil];
    
#if ESSENTIAL_GL_PRACTICES_SUPPORT_GL3 && defined(DEBUG)
    CGLEnable([context CGLContextObj], kCGLCECrashOnRemovedFunctions);
#endif
    
    [self setPixelFormat:pf];
    [self setOpenGLContext:context];
    
#if SUPPORT_RETINA_RESOLUTION
    [self setWantsBestResolutionOpenGLSurface:YES];
#endif
}

static const uint64_t NANOS_PER_USEC = 1000ULL;

static const uint64_t NANOS_PER_MILLISEC = 1000ULL * NANOS_PER_USEC;

static const uint64_t NANOS_PER_SEC = 1000ULL * NANOS_PER_MILLISEC;

- (void)videoRender {
    while (1) {
        
        // 渲染结束，线程退出;
        if (_isStop) {
            [NSThread exit];
        }
        
        // 若渲染暂停，需要等待信号量出发再继续;
        if (_isPause) {
            dispatch_semaphore_wait(_pauseSem, DISPATCH_TIME_FOREVER);
        }
        
        if ([self.renderDelegate respondsToSelector:@selector(getRenderImageData)]) {
            CSJVideoData *freshData = [self.renderDelegate getRenderImageData];
            
            if (freshData) {
                CSJVideoData *oldData = videoData;
                videoData = freshData;
                _renderSleep = freshData->getDuration();
                
                delete oldData;
                oldData = nullptr;
            }
        }
        
        uint64_t timeDiff = 0;
        uint64_t beginTime = mach_absolute_time();
        @autoreleasepool {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self drawView];
            });
        }
        timeDiff = mach_absolute_time() - beginTime;
        
        // 线程休眠;
        mach_timebase_info_data_t time_base;
        mach_timebase_info(&time_base);
        
        // 当休眠时长等于当前帧的展示时长时，会引起播放卡顿，将休眠时长乘以0.8之后，不会卡顿，目测音视频同步没有问题
        uint64_t time_to_wait = NANOS_PER_SEC * _renderSleep * 0.8 * time_base.denom / time_base.numer;
        uint64_t now = mach_absolute_time();
        
        mach_wait_until(now + time_to_wait - timeDiff);
    }
}

- (void)renderSleepWithTime:(double)sleepTime {
    mach_timebase_info_data_t time_base;
    mach_timebase_info(&time_base);
    
    uint64_t time_to_wait = sleepTime * time_base.denom / time_base.numer;
    uint64_t now = mach_absolute_time();
    
    mach_wait_until(now + time_to_wait);
}

- (void)renderSeekVideo {
    if ([self.renderDelegate respondsToSelector:@selector(getSeekImageData)]) {
        CSJVideoData *freshData = [self.renderDelegate getSeekImageData];
        
        if (!freshData) {
            return ;
        }
        
        CSJVideoData *oldData = videoData;
        videoData = freshData;
        _renderSleep = freshData->getDuration();
        
        delete oldData;
        oldData = nullptr;
        
        @autoreleasepool {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self drawView];
            });
        }
    }
}

- (void)createRenderThread {
    if (_renderThread) {
        [_renderThread cancel];
        _renderThread = nil;
    }
    
    _renderThread = [[NSThread alloc] initWithTarget:self selector:@selector(videoRender) object:nil];
    _renderSleep = 0.01;
    _pauseSem = dispatch_semaphore_create(0);
}

- (void)startRedner {
    // Activate the displaylink;
    //CVDisplayLinkStart(displayLink);
    
    _isStop = NO;
    _isPause = NO;
    
    [_renderThread start];
}

- (void)pauseRender {
    _isPause = YES;
}

- (void)resumeRender {
    _isPause = NO;
    dispatch_semaphore_signal(_pauseSem);
}

- (void)stopRender {
//    if (CVDisplayLinkIsRunning(displayLink)) {
//        CVDisplayLinkStop(displayLink);
//    }
    _isStop = YES;
}

- (void)prepareOpenGL {
    [super prepareOpenGL];
    
    // Make all the OpenGL calls to setup rendering
    // and build the necessary rendering objects.
    [self initGL];
    
//    // Create a display link capable of being used with all actives displays;
//    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
//
//    // Set the renderer output callback function;
//    CVDisplayLinkSetOutputCallback(displayLink, &myDisplayLinkDisplayCallback, (__bridge void*)self);
//
//    // Set the display link for the current renderer;
//    CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
//    CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
//    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
//
//    // Register to be notified when the window closes so we can stop the displaylink
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(windowWillClose:)
//                                                 name:NSWindowWillCloseNotification
//                                               object:[self window]];
    [self createRenderThread];
}

- (void)windowWillClose:(NSNotification*)notification {
    // Stop the display link when the window is closing because default
    // OpenGL render buffers will be destroyed. If display link continues to
    // fire without renderbuffers, OpenGL draw calls will set errors.
    
//    if (CVDisplayLinkIsRunning(displayLink)) {
//        NSLog(@"[%@] stop the displayLink", NSStringFromClass([self class]));
//        CVDisplayLinkStop(displayLink);
//    }
    if (_renderThread) {
        [self stopRender];
    }
}

- (void)initGL {
    [[self openGLContext] makeCurrentContext];
    
    GLint swapInt = 1;
    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
    
    if (_renderType == CSJRenderImageType_RGBA) {
        _render = [[CSJOpenGLRender alloc] initForRGBARender];
    } else if (_renderType == CSJRenderImageType_YUV420) {
        _render = [[CSJOpenGLRender alloc] initForYUV420];
    } else {
        NSLog(@"[%@] pixel format isn't support, render initialize error!", NSStringFromClass([self class]));
    }
}

- (void)reshape {
    [super reshape];
    
    CGLLockContext([[self openGLContext] CGLContextObj]);
    
    NSRect viewRectPoints = [self bounds];
    
#if SUPPORT_RETINA_RESOLUTION
    NSRect viewRectPixels = [self convertRectToBacking:viewRectPoints];
#else
    NSRect viewRectPixels = viewRectPoints;
#endif
    
    [_render resizeWithWidth:viewRectPixels.size.width
                      height:viewRectPixels.size.height];
    
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (CVReturn)getFrameForTime:(const CVTimeStamp *)outputTime {
    // There is no autorelease pool when this method is called
    // because it will be called from a backing thread.
    // It's important to create one or app can be leak.
    if ([self.renderDelegate respondsToSelector:@selector(getRenderImageData)]) {
        CSJVideoData *freshData = [self.renderDelegate getRenderImageData];
        
        if (freshData) {
            CSJVideoData *oldData = videoData;
            videoData = freshData;
            self.renderSleep = videoData->getDuration();
            
            delete oldData;
            oldData = nullptr;
        }
    }
    
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self drawView];
        });
    }
    
    return kCVReturnSuccess;
}

- (void)renewGState {
    [[self window] disableScreenUpdatesUntilFlush];
    
    [super renewGState];
}

- (void)drawRect:(NSRect)theRect {
    [self drawView];
}

- (void)drawView {
    [[self openGLContext] makeCurrentContext];
    
    CGLLockContext([[self openGLContext] CGLContextObj]);

    if (videoData) {
        NSInteger width = videoData->getWidth();
        NSInteger height = videoData->getHeight();
        NSData *data = nil;
        if (_renderType == CSJRenderImageType_RGBA) {
            data = [NSData dataWithBytes:videoData->getData() length:width * height * 3];
            [_render presenRGBAData:data width:width height:height];
        } else if (_renderType == CSJRenderImageType_YUV420) {
            data =[NSData dataWithBytes:videoData->getData() length:width * height * 3 / 2];
            [_render presentYUVData:data width:width height:height];
        }
        
        //NSLog(@"[%@] current picture timestamp: %f", NSStringFromClass([self class]), videoData->getFramePts());
    }
    
    CGLFlushDrawable([[self openGLContext] CGLContextObj]);
    CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void)setImage:(CVImageBufferRef)img {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [_render setImage:img];
    });
}

- (void)presentImageData:(NSData *)imageData width:(CGFloat)width height:(CGFloat)height {
    if (_renderType == CSJRenderImageType_RGBA) {
        if (!_saveData) {
            _saveData = imageData;
            _saveWidth = width;
            _saveHeight = height;
        }
        [_render presenRGBAData:imageData width:width height:height];
    } else if (_renderType == CSJRenderImageType_YUV420) {
        if (!_saveData) {
            _saveData = imageData;
            _saveWidth = width;
            _saveHeight = height;
        }
        [_render presentYUVData:imageData width:width height:height];
    }
}

@end
