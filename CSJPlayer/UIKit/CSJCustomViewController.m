//
//  CSJCustomViewController.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/23.
//

#import "CSJCustomViewController.h"

#import "NSView+UIView_Custom.h"

@interface CSJCustomViewController ()

@end

@implementation CSJCustomViewController

- (void)loadView {
    CGRect windowRect = CGRectMake(0, 0, 0, 0);
    self.view = [[NSView alloc] initWithFrame:windowRect];
    self.view.wantsLayer = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setBackgroundColor:(NSColor *)bgColor {
    [self.view setBackgroundColor:bgColor];
}

@end
