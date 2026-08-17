// SPDX-License-Identifier: MIT
#import "MBMenuBarWindow.h"
#import "MBMenuBarView.h"
#import "MBTheme.h"

@interface MBMenuBarWindow ()
@property (nonatomic, strong) MBMenuBarView *bar;
@property (nonatomic, assign) BOOL installed;
@property (nonatomic, assign) BOOL visible;
@end

@implementation MBMenuBarWindow

+ (instancetype)sharedWindow {
    static MBMenuBarWindow *w; static dispatch_once_t t;
    dispatch_once(&t, ^{ w = [[self alloc] init]; });
    return w;
}

- (instancetype)init {
    UIWindow *host = [UIApplication sharedApplication].windows.firstObject;
    UIEdgeInsets sf = host.safeAreaInsets;
    CGFloat top = sf.top > 0 ? sf.top : 20.0f;
    CGRect frame = CGRectMake(0, top, host.bounds.size.width, MBMenuBarHeight());
    if ((self = [super initWithFrame:host.bounds])) {
        self.windowLevel = UIWindowLevelStatusBar + 1;
        self.backgroundColor = UIColor.clearColor;
        self.hidden = YES;
        _bar = [MBMenuBarView sharedBar];
        _bar.frame = frame;
        [self addSubview:_bar];
    }
    return self;
}

- (void)installInHost:(UIWindow *)host {
    if (_installed) return;
    [host addSubview:self];
    _installed = YES;
}

- (void)show {
    self.hidden = NO;
    _visible = YES;
    [_bar reloadStatusItems];
}

- (void)hide {
    self.hidden = YES;
    _visible = NO;
}

- (BOOL)isVisible { return _visible; }

- (void)reloadStatusItems { [_bar reloadStatusItems]; }

- (void)presentMenu:(NSMenu *)menu fromRect:(CGRect)rect {
    [_bar presentMenu:menu fromRect:rect];
}

@end
