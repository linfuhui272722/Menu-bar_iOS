// SPDX-License-Identifier: MIT
// Pull-down menu window presenting an NSMenu (AppKit popUpContextMenu parity).
#import <UIKit/UIKit.h>
#import "MBCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBMenuWindow : UIWindow
- (instancetype)initWithMenu:(NSMenu *)menu origin:(CGRect)origin;
- (void)close;
@end

NS_ASSUME_NONNULL_END
