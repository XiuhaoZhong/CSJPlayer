//
//  DevicesComboView.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/8/7.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DevicesComboView : NSView

/* 选择了一项的block */
@property (nonatomic, copy) void(^selectedItem)(NSInteger index);

- (instancetype)initWithDeviceArray:(NSArray *)deviceArray;

@end

NS_ASSUME_NONNULL_END
