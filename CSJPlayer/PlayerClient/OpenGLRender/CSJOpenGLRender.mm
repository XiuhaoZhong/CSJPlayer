//
//  CSJOpenGLRender.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/25.
//

#import "CSJOpenGLRender.h"

#include "glUtil.h"

@interface CSJOpenGLRender () {
    // global data;
    GLuint program_;
    GLuint vertexArray_;
    int    videoW_;
    int    videoH_;
    int    viewW_;
    int    viewH_;
    
    // YUV420 data;
    GLuint id_y;
    GLuint id_u;
    GLuint id_v;
    GLuint textureUniformY_;
    GLuint textureUniformU_;
    GLuint textureUniformV_;
    GLuint vertexBuffer_;
    GLuint vertexAttribute_;
    GLuint textureAttribute_;
    unsigned char *pBufYuv420p_;
    unsigned char *pBuffer_;
    
    // rgba data;
    GLuint texture_rgba;
    GLint  textureUniformRGBA_;
    unsigned char *pBufRGBA_;
}

@end

@implementation CSJOpenGLRender

- (void)renderYUVData:(unsigned char *)yuv420Data {
    
    [self clearRenderBuffer];
    
    float x, y;
    float rationW = (float)viewW_ / videoW_;
    float rationH = (float)viewH_ / videoH_;
    
    float minRation = rationW < rationH ? rationW : rationH;
    
    y = videoH_ * minRation / viewH_;
    x = viewW_ * minRation / viewW_;
    
//    float vertexPoints[] = {
//        -x, -y,  0.0f,  1.0f,
//         x, -y,  1.0f,  1.0f,
//        -x,  y,  0.0f,  0.0f,
//         x,  y,  1.0f,  0.0f,
//    };
//
//    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
//    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(float), vertexPoints, GL_STATIC_DRAW);
//    //glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(float), vertexPoints, GL_STATIC_DRAW);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, id_y);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, videoW_, videoH_, 0, GL_RED, GL_UNSIGNED_BYTE, yuv420Data);
    glUniform1i(textureUniformY_, 0);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, id_u);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, videoW_ / 2, videoH_ / 2, 0, GL_RED, GL_UNSIGNED_BYTE, (char*)yuv420Data + videoW_ * videoH_);
    glUniform1i(textureUniformU_, 1);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, id_v);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, videoW_ / 2, videoH_ / 2, 0, GL_RED, GL_UNSIGNED_BYTE, (char*)yuv420Data + videoW_ * videoH_ * 5 / 4);
    glUniform1i(textureUniformV_, 2);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)renderRGBA:(unsigned char *)rgbaData {
    glClearColor(0.0f, 0.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindTexture(GL_TEXTURE_2D, texture_rgba);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)videoW_, (GLsizei)videoH_, 0, GL_RGB, GL_UNSIGNED_BYTE, rgbaData);
    
    float x, y;
    float rationW = (float)viewW_ / videoW_;
    float rationH = (float)viewH_ / videoH_;
    
    float minRation = rationW < rationH ? rationW : rationH;
    
    y = videoH_ * minRation / viewH_;
    x = viewW_ * minRation / viewW_;
    
//    float vertexPoints[] = {
//        -x, -y,  0.0f,  1.0f,
//         x, -y,  1.0f,  1.0f,
//        -x,  y,  0.0f,  0.0f,
//         x,  y,  1.0f,  0.0f,
//    };
//    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(float), vertexPoints, GL_STATIC_DRAW);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture_rgba);
    glUniform1i(textureUniformRGBA_, 0);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (void)setImage:(CVImageBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    {
        GLuint width = (GLuint)CVPixelBufferGetWidth(pixelBuffer);
        GLuint height = (GLuint)CVPixelBufferGetHeight(pixelBuffer);
        
        [self resizeWithWidth:width height:height];
        
        pBufYuv420p_ = NULL;
        pBufYuv420p_ = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
        
        [self renderYUVData:pBufYuv420p_];
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)presentYUVData:(NSData *)yuvData width:(int)width height:(int)height {
    @synchronized (self) {
        videoW_ = width;
        videoH_ = height;
        
        pBufYuv420p_ = NULL;
        pBufYuv420p_ = (unsigned char *)[yuvData bytes];
        
        [self renderYUVData:pBufYuv420p_];
    }
}

- (void)presenRGBAData:(NSData *)rgbaData width:(int)width height:(int)height {
    @synchronized (self) {
        videoW_ = width;
        videoH_ = height;
        
        pBufRGBA_ = NULL;
        pBufRGBA_ = (unsigned char *)[rgbaData bytes];
        
        [self renderRGBA:pBufRGBA_];
    }
}

- (instancetype)initForYUV420 {
    if (self = [super init]) {
        NSLog(@"Render: %s; Version: %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));

        [self initGLForYUV420];
        [self clearRenderBuffer];
    }
    
    return self;
}

- (instancetype)initForRGBARender {
    if (self = [super init]) {
        NSLog(@"Render: %s; Version: %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
        
        [self initGLForRGBA];
        [self clearRenderBuffer];
    }
    
    return self;
}

- (void)compileShader:(GLuint &)shader type:(GLenum)type file:(NSString *)shaderFile {
    //读取字符串
    NSString* content = [NSString stringWithContentsOfFile:shaderFile encoding:NSUTF8StringEncoding error:nil];
    const GLchar* source = (GLchar *)[content UTF8String];
    
    shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    
    //错误分析
    GLint  compiled;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled );
    if ( !compiled ) {
        GLint  logSize;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logSize );
        char* logMsg = new char[logSize];
        glGetShaderInfoLog(shader, logSize, NULL, logMsg );
        NSLog(@"Shader compile log:%s\n", logMsg);
        delete [] logMsg;
        exit(EXIT_FAILURE);
    }
}

- (GLuint)loadShaders:(NSString *)vsFile frag:(NSString *)fragFile {
    
    GLuint vsShader, fragShader;
    GLint program = glCreateProgram();
    
    [self compileShader:vsShader type:GL_VERTEX_SHADER file:vsFile];
    [self compileShader:fragShader type:GL_FRAGMENT_SHADER file:fragFile];
    
    glAttachShader(program, vsShader);
    glAttachShader(program, fragShader);
    
    glDeleteShader(vsShader);
    glDeleteShader(fragShader);
    
    return program;
}

/// Generate the program;
/// - Parameter shaderName: vertex shader file and fragment shader file's name;
///  e.g: yuv_shader.vs  && yuv_shader.frag
///     rgba_shader.vs && rgba_shader.frag
- (void)prepareShaderWithShaderName:(NSString *)shaderName {
    NSString *vsFilePath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"vs"];
    NSString *fragFilePath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"frag"];
    
    program_ = [self loadShaders:vsFilePath frag:fragFilePath];
    glLinkProgram(program_);
    
    GLint linked;
    glGetProgramiv(program_, GL_LINK_STATUS, &linked);
    if (!linked) {
        NSLog(@"Shader program failed to link");
        GLint  logSize;
        glGetProgramiv(program_, GL_INFO_LOG_LENGTH, &logSize);
        char* logMsg = new char[logSize];
        glGetProgramInfoLog(program_, logSize, NULL, logMsg );
        NSLog(@"Link Error: %s", logMsg);
        delete [] logMsg;
            
        exit( EXIT_FAILURE );
    }
    
    glUseProgram(program_);
}

- (void)initGLForYUV420 {
    [self prepareShaderWithShaderName:@"yuv_shader"];
    
    textureUniformY_ = glGetUniformLocation(program_, "tex_y");
    textureUniformU_ = glGetUniformLocation(program_, "tex_u");
    textureUniformV_ = glGetUniformLocation(program_, "tex_v");
    
    float vertexPoints[] = {
        -1.0f, -1.0f,  0.0f, 1.0f,
         1.0f, -1.0f,  1.0f, 1.0f,
        -1.0f,  1.0f,  0.0f, 0.0f,
         1.0f,  1.0f,  1.0f, 0.0f,
    };
    
    glGenVertexArrays(1, &vertexArray_);
    glBindVertexArray(vertexArray_);
    
    glGenBuffers(1, &vertexBuffer_);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(float), vertexPoints, GL_STATIC_DRAW);
    
    vertexAttribute_ = glGetAttribLocation(program_, "vertexIn");
    textureAttribute_ = glGetAttribLocation(program_, "textureIn");
    //glEnableVertexAttribArray(vertexAttribute_);
    glVertexAttribPointer(vertexAttribute_, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4, (const GLvoid *)0);
    glEnableVertexAttribArray(vertexAttribute_);
    //glEnableVertexAttribArray(textureAttribute_);
    glVertexAttribPointer(textureAttribute_, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4, (const GLvoid *)(sizeof(float) * 2));
    glEnableVertexAttribArray(textureAttribute_);
    
    //Init Texture
    glGenTextures(1, &id_y);
    glBindTexture(GL_TEXTURE_2D, id_y);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    glGenTextures(1, &id_u);
    glBindTexture(GL_TEXTURE_2D, id_u);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
    glGenTextures(1, &id_v);
    glBindTexture(GL_TEXTURE_2D, id_v);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)initGLForRGBA {
    [self prepareShaderWithShaderName:@"rgba_shader"];
    
    float vertexPoints[] = {
        -1.0f, -1.0f,  0.0f, 1.0f,
         1.0f, -1.0f,  1.0f, 1.0f,
        -1.0f,  1.0f,  0.0f, 0.0f,
         1.0f,  1.0f,  1.0f, 0.0f,
    };
    
    glGenVertexArrays(1, &vertexArray_);
    glBindVertexArray(vertexArray_);
    
    glGenBuffers(1, &vertexBuffer_);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer_);
    glBufferData(GL_ARRAY_BUFFER, 4 * 4 * sizeof(float), vertexPoints, GL_STATIC_DRAW);
    
    vertexAttribute_ = glGetAttribLocation(program_, "position");
    textureAttribute_ = glGetAttribLocation(program_, "texcoord");
    glEnableVertexAttribArray(vertexAttribute_);
    glVertexAttribPointer(vertexAttribute_, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4, (const GLvoid *)0);
    glEnableVertexAttribArray(textureAttribute_);
    glVertexAttribPointer(textureAttribute_, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 4, (const GLvoid *)(sizeof(float) * 2));
    
    textureUniformRGBA_ = glGetUniformLocation(program_, "inputImageTexture");
    
    //Init Texture
    glGenTextures(1, &texture_rgba);
    glBindTexture(GL_TEXTURE_2D, texture_rgba);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
}

- (void)initializeGL {
    
    // 渲染yuv420;
    [self initGLForYUV420];
    
    
}

- (void)clearRenderBuffer {
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)resizeWithWidth:(GLuint)width height:(GLuint)height {
    glViewport(0, 0, width, height);
    
    viewW_ = width;
    viewH_ = height;
    
    if (viewW_ == 0) {
        
    }
    
    if (viewH_ == 0) {
        
    }
    
    [self clearRenderBuffer];
}

- (void)render {
    
}

@end
