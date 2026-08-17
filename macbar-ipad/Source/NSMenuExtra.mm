// SPDX-License-Identifier: MIT
// UIKit rewrite of AppKit NSMenuExtra — base class for dynamically-loadable
// right-side items. The macOS .menu bundles declare a subclass via
// NSPrincipalClass (e.g. AppleClockExtra) and NSMenuExtraWidth; here we keep
// the same contract: -initWithFrame:, menuExtraView, menu, menuWillOpen/Close.
#import "MBCore.h"
#import "MBTheme.h"

@implementation NSMenuExtra

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super init])) {
        _menuExtraWidth = frame.size.width;
        _menuExtraView = [[UIView alloc] initWithFrame:frame];
        _menuExtraView.backgroundColor = UIColor.clearColor;
    }
    return self;
}

- (void)menuWillOpen {}
- (void)menuDidClose {}

@end
