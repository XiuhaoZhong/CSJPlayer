//
//  ViewController.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/3/21.
//

#import "ViewController.h"
#import "CSJPlayerController.h"
#import "CSJMediaRecordingVC.h"

#import "Masonry.h"

@interface ViewController () <NSViewControllerPresentationAnimator>

@property (nonatomic, strong) NSButton *toPlayerVCBtn;
@property (nonatomic, strong) NSButton *toRecordingVCBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    [self initUI];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)initUI {
    [self.view addSubview:self.toPlayerVCBtn];
    
    [self.toPlayerVCBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(0);
        make.size.mas_equalTo(CGSizeMake(60, 20));
    }];
    
    [self.view addSubview:self.toRecordingVCBtn];
    [self.toRecordingVCBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(0);
        make.top.equalTo(self.toPlayerVCBtn.mas_bottom).offset(10);
        make.size.mas_equalTo(CGSizeMake(80, 20));
    }];
}

- (void)showPlayerVC {
    CSJPlayerController *playerVC = [[CSJPlayerController alloc] init];
    playerVC.view.frame = self.view.frame;
    
    [self addChildViewController:playerVC];
    [self presentViewController:playerVC animator:self];
}

- (void)showRecordingVC {
    CSJMediaRecordingVC *recordingVC = [[CSJMediaRecordingVC alloc] init];
    recordingVC.view.frame = self.view.frame;
    
    [self addChildViewController:recordingVC];
    [self presentViewController:recordingVC animator:self];
}

#pragma mark -- NSViewControllerPresentationAnimator;
- (void)animatePresentationOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    NSView *containerView = fromViewController.view;
    
    NSView *showView = viewController.view;
    [containerView addSubview:showView];
    [showView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];

    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 0.5;
    } completionHandler:^{
        
    }];
}

- (void)animateDismissalOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController {
    NSView *containerView = fromViewController.view;
    
    CGRect curFrame = containerView.frame;
    CGRect finalRect = CGRectMake(CGRectGetMaxX(curFrame), CGRectGetMinY(curFrame), CGRectGetWidth(curFrame), CGRectGetHeight(curFrame));
    
    NSView *showView = viewController.view;
    showView.frame = finalRect;
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
        context.duration = 0.5;
        showView.animator.frame = finalRect;
    } completionHandler:^{
        [showView removeFromSuperview];
    }];
}

- (void)btnClicked:(NSButton *)sender {
    if (sender == _toPlayerVCBtn) {
        [self showPlayerVC];
    } else if (sender == _toRecordingVCBtn) {
        [self showRecordingVC];
    }
}

#pragma mark -- getters;
- (NSButton *)toPlayerVCBtn {
    if (!_toPlayerVCBtn) {
        _toPlayerVCBtn = [NSButton buttonWithTitle:@"player" target:self action:@selector(btnClicked:)];
    }
    
    return _toPlayerVCBtn;
}

- (NSButton *)toRecordingVCBtn {
    if (!_toRecordingVCBtn) {
        _toRecordingVCBtn = [NSButton buttonWithTitle:@"recorder" target:self action:@selector(btnClicked:)];
    }
    
    return _toRecordingVCBtn;
}

@end
