// SPDX-License-Identifier: MIT
#import "MBRotationLockExtra.h"
#import "MBTheme.h"
#import "MBPrivateDecls.h"

@interface MBRotationLockExtra ()
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, assign) BOOL locked;
@end

@implementation MBRotationLockExtra

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 22, MBMenuBarHeight())])) {
        _icon = [[UIImageView alloc] initWithFrame:CGRectMake(3, 2, 16, MBMenuBarHeight() - 4)];
        _icon.contentMode = UIViewContentModeScaleAspectFit;
        _icon.tintColor = [MBTheme menuBarTextColor];
        [self.menuExtraView addSubview:_icon];
        [self _refresh];
        self.menu = [self _buildMenu];
    }
    return self;
}

- (BOOL)_isLocked {
    Class c = MBClassNamed(@"SBDeviceOrientationLockManager");
    if (c) {
        id m = [c performSelector:NSSelectorFromString(@"sharedInstance")];
        if (m) return [[m valueForKey:@"isLocked"] boolValue];
    }
    return _locked;
}

- (void)_setLocked:(BOOL)l {
    _locked = l;
    Class c = MBClassNamed(@"SBDeviceOrientationLockManager");
    if (c) {
        id m = [c performSelector:NSSelectorFromString(@"sharedInstance")];
        if (m) [m performSelector:NSSelectorFromString(l ? @"lock" : @"unlock")];
    }
}

- (void)_refresh {
    _locked = [self _isLocked];
    _icon.image = [self _lockIcon];
}

- (UIImage *)_lockIcon {
    // SF Symbols available iOS 13+. Fallback to a simple drawn glyph.
    UIImage *img = [UIImage systemImageNamed:_locked ? @"lock.rotation" : @"lock.rotation.open"];
    if (img) { img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]; return img; }
    CGSize s = CGSizeMake(16, 16); UIGraphicsBeginImageContextWithOptions(s, NO, 0);
    [[MBTheme menuBarTextColor] setStroke];
    UIBezierPath *p = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3, 6, 10, 9) cornerRadius:1.5];
    p.lineWidth = 1.5; [p stroke];
    UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:CGPointMake(8, 6) radius:3 startAngle:M_PI endAngle:0 clockwise:YES];
    arc.lineWidth = 1.5; [arc stroke];
    UIImage *r = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext();
    return r;
}

- (NSMenu *)_buildMenu {
    NSMenu *m = [[NSMenu alloc] initWithTitle:@"Rotation Lock"];
    NSMenuItem *toggle = [[NSMenuItem alloc] initWithTitle:(_locked ? @"Unlock Rotation" : @"Lock Rotation")
                                                    action:@selector(_toggle) target:self];
    [m addItem:toggle];
    return m;
}

- (void)_toggle { [self _setLocked:!_locked]; [self _refresh]; self.menu = [self _buildMenu]; }

@end
