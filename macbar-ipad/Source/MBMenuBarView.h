// SPDX-License-Identifier: MIT
// MBMenuBarView — the bar content view. Left zone = app menu (Apple menu +
// frontmost-app menu), right zone = NSStatusBar status items. Mirrors the
// macOS split rendered by AppKit's menubar.
#import <UIKit/UIKit.h>
#import "MBCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBMenuBarView : UIView
+ (instancetype)sharedBar;
- (void)reloadStatusItems;
- (void)presentMenu:(NSMenu *)menu fromRect:(CGRect)rect;
- (void)updateFrontmostApplication:(nullable NSString *)bundleID
                         displayName:(nullable NSString *)name
                                icon:(nullable UIImage *)icon;
@end

NS_ASSUME_NONNULL_END
