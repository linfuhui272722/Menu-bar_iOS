// SPDX-License-Identifier: MIT
#import "MBMenuBarWindow.h"
#import "MBMenuBarView.h"
#import "MBTheme.h"
#import "MBLog.h"

@interface MBMenuBarWindow ()
@property (nonatomic, strong) MBMenuBarView *bar;
@property (nonatomic, assign) BOOL visible;
@end

@implementation MBMenuBarWindow

+ (instancetype)sharedWindow {
    static MBMenuBarWindow *w; static dispatch_once_t t;
    dispatch_once(&t, ^{ w = [[self alloc] init]; });
    return w;
}

- (instancetype)init {
    // On multi-scene iOS the keyWindow may not be the first object; scan for
    // a window with non-zero bounds, fall back to the main screen bounds.
    UIWindow *host = nil;
    for (UIWindow *w in [UIApplication sharedApplication].windows) {
        if (CGRectGetWidth(w.bounds) > 10) { host = w; break; }
    }
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    CGRect hostBounds = host ? host.bounds : screenBounds;
    UIEdgeInsets sf = host ? host.safeAreaInsets : UIEdgeInsetsZero;
    CGFloat top = sf.top > 0 ? sf.top : 20.0f;
    CGRect barFrame = CGRectMake(0, top, screenBounds.size.width, MBMenuBarHeight());
    MBLog(@"MBMenuBarWindow.init: host=%@ hostBounds=%@ top=%g barHeight=%g",
          host ? NSStringFromClass([host class]) : @"nil",
          NSStringFromCGRect(hostBounds), top, (CGFloat)MBMenuBarHeight());
    if ((self = [super initWithFrame:barFrame])) {
        self.windowLevel = UIWindowLevelStatusBar + 1;
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = YES;
        self.hidden = YES;
        _bar = [MBMenuBarView sharedBar];
        _bar.frame = self.bounds;
        [self addSubview:_bar];
        MBLog(@"MBMenuBarWindow.init: window frame=%@ windowLevel=%g bar=%@",
              NSStringFromCGRect(self.frame), (CGFloat)self.windowLevel,
              NSStringFromClass([_bar class]));
    }
    return self;
}

// Independent UIWindow: just unhide it. Do NOT nest a UIWindow as a subview
// of another UIWindow — that does not render on iOS.
- (void)makeVisible {
    self.hidden = NO;
    _visible = YES;
    [_bar reloadStatusItems];
    MBLog(@"MBMenuBarWindow.makeVisible: hidden=%d frame=%@ subviews=%lu",
          (int)self.hidden, NSStringFromCGRect(self.frame),
          (unsigned long)self.subviews.count);
}

// Back-compat with older callers (installInHost is now a no-op; the window
// shows itself). Kept so existing call sites keep compiling.
- (void)installInHost:(UIWindow *)host { (void)host; }
- (void)show { [self makeVisible]; }

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
