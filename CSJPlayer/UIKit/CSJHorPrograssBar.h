//
//  CSJHorPrograssBar.h
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN
/*
 * A horizontal prograss bar, it support changing the
 * prograss by dragging icon, clicking direction keys
 * on the keyboard and so on. It also can change the
 * prograss with the time line of external.
 *
 */
@interface CSJHorPrograssBar : NSView

@property (nonatomic, copy) void(^updateTimeBlock)(CGFloat);
@property (nonatomic, copy) void(^notifySeekBlock)(BOOL);

- (void)updateCursorPos:(CGFloat)rate;

@end

NS_ASSUME_NONNULL_END
