//
//  CSJHorPrograssBar.m
//  CSJPlayer
//
//  Created by Xiuhao Zhong on 2023/4/22.
//

#import "CSJHorPrograssBar.h"
#import "Masonry.h"

@interface CSJHorPrograssBar ()

@property (nonatomic, strong) NSView *cursorView;
@property (nonatomic, strong) NSView *prograssView;
@property (nonatomic, strong) NSView *playedView;

@property (nonatomic, assign) BOOL   mouseDownInCursor;

@end

@implementation CSJHorPrograssBar

- (instancetype)initWithFrame:(NSRect)frameRect {
    if (self = [super initWithFrame:frameRect]) {
        _mouseDownInCursor = NO;
        
        [self initUI];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}

- (void)initUI {
    [self addSubview:self.prograssView];
    [self.prograssView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(5);
        make.right.mas_equalTo(-5);
        make.height.mas_equalTo(10);
        make.centerY.mas_equalTo(0);
    }];
    
    [self addSubview:self.playedView];
    self.playedView.frame = NSMakeRect(5, 2.5, 0, 10);
    [self addSubview:self.cursorView];
}

- (void)updateCursorPos:(CGFloat)rate {
    CGFloat newX = self.prograssView.frame.size.width * rate;
    CGRect cursorFrame = self.cursorView.frame;
    
    CGFloat cursorX = self.prograssView.frame.origin.x + newX - 5;
    
    self.cursorView.frame = NSMakeRect(cursorX,
                                       cursorFrame.origin.y,
                                       cursorFrame.size.width,
                                       cursorFrame.size.height);
    
    self.playedView.frame = self.playedView.frame = NSMakeRect(5, 2.5, newX, 10);
}

#pragma mark - overrides from NSResponder;
- (void)mouseDown:(NSEvent *)event {
    NSPoint downPt = [event locationInWindow];;
    NSPoint innerPt = [self convertPoint:downPt fromView:nil];
    if (NSPointInRect(innerPt, self.cursorView.frame)) {
        if (self.notifySeekBlock) {
            self.notifySeekBlock(YES);
        }
        _mouseDownInCursor = YES;
    } else if (NSPointInRect(innerPt, self.prograssView.frame)) {
        CGRect cursorFrame = self.cursorView.frame;
        self.cursorView.frame = NSMakeRect(innerPt.x - 5,
                                           cursorFrame.origin.y,
                                           cursorFrame.size.width,
                                           cursorFrame.size.height);
        
        self.playedView.frame = self.playedView.frame = NSMakeRect(5, 2.5, innerPt.x - 5, 10);
        if (self.notifySeekBlock) {
            self.notifySeekBlock(YES);
        }
        if (self.updateTimeBlock) {
            self.updateTimeBlock(self.playedView.frame.size.width / self.prograssView.frame.size.width);
        }
        if (self.notifySeekBlock) {
            self.notifySeekBlock(NO);
        }
    }
}

- (void)mouseUp:(NSEvent *)event {
    if (self.notifySeekBlock && _mouseDownInCursor == YES) {
        self.notifySeekBlock(NO);
    }
    
    _mouseDownInCursor = NO;
}

- (void)mouseDragged:(NSEvent *)event {
    if (_mouseDownInCursor) {
        CGFloat maxX = self.frame.size.width - 10;
        
        CGFloat delX = event.deltaX;
        CGFloat newX = self.cursorView.frame.origin.x + delX;
        if (newX <= 0) {
            newX = 0;
        } else if (newX >= maxX) {
            newX = maxX;
        }
        
        CGRect cursorFrame = self.cursorView.frame;
        self.cursorView.frame = NSMakeRect(newX,
                                           cursorFrame.origin.y,
                                           cursorFrame.size.width,
                                           cursorFrame.size.height);
        
        self.playedView.frame = self.playedView.frame = NSMakeRect(5, 2.5, newX, 10);
        
        CGFloat playedRate = newX / self.prograssView.frame.size.width;
        if (self.updateTimeBlock) {
            self.updateTimeBlock(playedRate);
        }
        
    }
}

#pragma mark - getters;
- (NSView *)cursorView {
    if (!_cursorView) {
        _cursorView = [[NSView alloc] initWithFrame:NSMakeRect(0, 2.5, 10, 10)];
        
        CALayer *viewLayer = [CALayer layer];
        NSView *backgroundView = _cursorView;
        [backgroundView setWantsLayer:YES];
        [backgroundView setLayer:viewLayer];
        backgroundView.layer.backgroundColor = [NSColor yellowColor].CGColor;
        [backgroundView setNeedsDisplay:YES];
        
        _cursorView.layer.cornerRadius = 5;
        _cursorView.layer.masksToBounds = YES;
    }
    
    return _cursorView;
}

- (NSView *)prograssView {
    if (!_prograssView) {
        _prograssView = [[NSView alloc] initWithFrame:NSZeroRect];
        CALayer *viewLayer = [CALayer layer];
        NSView *backgroundView = _prograssView;
        [backgroundView setWantsLayer:YES];
        [backgroundView setLayer:viewLayer];
        backgroundView.layer.backgroundColor = [NSColor grayColor].CGColor;
        [backgroundView setNeedsDisplay:YES];
    }
    
    return _prograssView;
}

- (NSView *)playedView {
    if (!_playedView) {
        _playedView = [[NSView alloc] initWithFrame:NSZeroRect];
        CALayer *viewLayer = [CALayer layer];
        NSView *backgroundView = _playedView;
        [backgroundView setWantsLayer:YES];
        [backgroundView setLayer:viewLayer];
        backgroundView.layer.backgroundColor = [NSColor greenColor].CGColor;
        [backgroundView setNeedsDisplay:YES];
    }
    
    return _playedView;
}

@end
