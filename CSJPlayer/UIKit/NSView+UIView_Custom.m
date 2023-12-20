//
//  NSView+UIView_Custom.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/8/7.
//

#import "NSView+UIView_Custom.h"

@implementation NSView (UIView_Custom)

- (void)setBackgroundColor:(NSColor *)bgColor {
    CALayer *viewLayer = [CALayer layer];
    NSView *backgroundView = self;
    [backgroundView setWantsLayer:YES];
    [backgroundView setLayer:viewLayer];
    backgroundView.layer.backgroundColor = bgColor.CGColor;
    [backgroundView setNeedsDisplay:YES];
}

@end
