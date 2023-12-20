//
//  CSJAVFoundDecoder.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/6/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/* Decoder based AVFoundation */ 
@interface CSJAVFoundDecoder : NSObject

- (instancetype)initWithUrl:(NSString *)mediaURL;

- (void)outputTrackInfos;

@end

NS_ASSUME_NONNULL_END
