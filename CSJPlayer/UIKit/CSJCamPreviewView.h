//
//  CSJCamPreviewView.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/8/4.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AVCaptureSession;

@interface CSJCamPreviewView : NSView

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVCaptureSession *captureSession;

@end

NS_ASSUME_NONNULL_END
