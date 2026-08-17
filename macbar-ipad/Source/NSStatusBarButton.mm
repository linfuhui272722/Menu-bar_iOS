// SPDX-License-Identifier: MIT
// UIKit rewrite of AppKit NSStatusBarButton — the clickable icon cell in a
// status item. Owns highlight drawing (NSStatusBarButtonCell parity).
#import "MBCore.h"
#import "MBTheme.h"

@implementation NSStatusBarButton

- (instancetype)initWithFrame:(CGRect)frame inStatusBar:(NSStatusBar *)statusBar {
    if ((self = [super initWithFrame:frame])) {
        _statusItem = nil;
        self.backgroundColor = UIColor.clearColor;
        self.showsTouchWhenHighlighted = NO;
        self.adjustsImageWhenHighlighted = YES;
        [self setTitleColor:[MBTheme menuBarTextColor] forState:UIControlStateNormal];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (self.highlighted || self.state == UIControlStateSelected) {
        [[[MBTheme menuHighlightColor] colorWithAlphaComponent:0.30] setFill];
        UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:rect
                                                  cornerRadius:4.0];
        [p fill];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.selected = YES;
    [self setNeedsDisplay];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.selected = NO;
    [self setNeedsDisplay];
    if (self.statusItem) {
        if (self.statusItem.menu) {
            // popupStatusBarMenu: parity: open pull-down menu anchored here.
            [[NSNotificationCenter defaultCenter]
                postNotificationName:@"MBStatusItemMenuRequested"
                                object:self.statusItem];
        } else if (self.statusItem.target && self.statusItem.action) {
            [self.statusItem.target performSelector:self.statusItem.action
                                         withObject:self.statusItem];
        }
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.selected = NO;
    [self setNeedsDisplay];
    [super touchesCancelled:touches withEvent:event];
}

@end
