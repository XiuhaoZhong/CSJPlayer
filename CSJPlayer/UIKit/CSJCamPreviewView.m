//
//  CSJCamPreviewView.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/8/4.
//

#import "CSJCamPreviewView.h"

@implementation CSJCamPreviewView

+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)captureSession {
    return self.videoPreviewLayer.session;
}

- (void)setCaptureSession:(AVCaptureSession *)captureSession {
    self.videoPreviewLayer.session = captureSession;
}

@end
