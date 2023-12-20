//
//  CSJMideoInfoView.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/24.
//

#import <Cocoa/Cocoa.h>


NS_ASSUME_NONNULL_BEGIN

class CSJVideoInformation;
@interface CSJMediaInfoView : NSView {
    CSJVideoInformation *mediaInfo;
}

- (void)loadMediaInfo:(CSJVideoInformation *)medioInfo;

@end

NS_ASSUME_NONNULL_END
