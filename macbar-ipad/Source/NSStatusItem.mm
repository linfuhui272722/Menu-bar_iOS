// SPDX-License-Identifier: MIT
// UIKit rewrite of AppKit NSStatusItem.
#import "MBCore.h"
#import "MBTheme.h"

@interface NSStatusItem ()
@property (nonatomic, weak) NSStatusBar *sb;
@property (nonatomic, strong) NSStatusBarButton *button;
@property (nonatomic) NSInteger priority;
@end

@implementation NSStatusItem

@synthesize length = _length;

- (instancetype)_initInStatusBar:(NSStatusBar *)statusBar
                         withLength:(CGFloat)length
                        withPriority:(NSInteger)priority {
    if ((self = [super init])) {
        _sb = statusBar;
        _length = length;
        _priority = priority;
        _enabled = YES;
        CGFloat w = (length == NSVariableStatusItemLength) ? 0.0f : length;
        _button = [[NSStatusBarButton alloc] initWithFrame:CGRectMake(0, 0, w, MBMenuBarHeight()) inStatusBar:statusBar];
        _button.statusItem = self;
        [_button addTarget:self action:@selector(_buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)setLength:(CGFloat)length {
    if (_length == length) return;
    _length = length;
    [self _adjustLength];
}
- (void)setImage:(UIImage *)image { _image = image; [self _updateButton]; }
- (void)setTitle:(NSString *)title { _title = [title copy]; [self _updateButton]; }
- (void)setAlternateImage:(UIImage *)img { _alternateImage = img; }
- (void)setMenu:(NSMenu *)menu { _menu = menu; }
- (void)setView:(UIView *)view {
    _view = view;
    [self _adjustLength];
}
- (NSStatusBarButton *)button { return _button; }
- (NSStatusBar *)statusBar { return _sb; }

- (void)sendActionOn:(NSUInteger)mask { /* AppKit parity no-op */ }

- (void)_buttonAction:(NSStatusBarButton *)b {
    if (self.menu) {
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"MBStatusItemMenuRequested" object:self];
    } else if (self.target && self.action) {
        [self.target performSelector:self.action withObject:self];
    }
}

- (void)_updateButton {
    if (self.title) [_button setTitle:self.title forState:UIControlStateNormal];
    if (self.image) [_button setImage:self.image forState:UIControlStateNormal];
    if (self.alternateImage) [_button setImage:self.alternateImage forState:UIControlStateSelected];
    [self _adjustLength];
}

- (void)_adjustLength {
    // Auto-size when length == NSVariableStatusItemLength, mirroring AppKit.
    if (self.view) {
        _button.frame = self.view.bounds;
        return;
    }
    if (_length == NSVariableStatusItemLength) {
        [_button sizeToFit];
        CGRect f = _button.frame; f.size.height = MBMenuBarHeight();
        _button.frame = f;
    } else {
        CGRect f = _button.frame;
        f.size.width = _length;
        f.size.height = MBMenuBarHeight();
        _button.frame = f;
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"MBStatusBarItemsDidChange" object:self.statusBar];
}

@end
