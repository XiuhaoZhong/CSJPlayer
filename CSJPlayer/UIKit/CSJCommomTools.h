//
//  CSJCommomTools.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSJCommomTools : NSObject

@end

@interface CSJTimeTools : NSObject

+ (NSString *)time_HHMMSSFromSecs:(NSInteger)secs;

@end

NS_ASSUME_NONNULL_END
