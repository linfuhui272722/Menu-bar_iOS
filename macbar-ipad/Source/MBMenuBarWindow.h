// SPDX-License-Identifier: MIT
// MBMenuBarWindow — the top overlay window hosting the macOS-style menu bar.
// Sits just below the iOS system status bar and spans the full screen width.
// Internally split into left (app menus) and right (NSStatusBar items).
#import <UIKit/UIKit.h>
#import "MBCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBMenuBarWindow : UIWindow
+ (instancetype)sharedWindow;
- (void)installInHost:(UIWindow *)host;
- (void)show;
- (void)hide;
- (BOOL)isVisible;
- (void)reloadStatusItems;
- (void)presentMenu:(NSMenu *)menu fromRect:(CGRect)rect;
@end

NS_ASSUME_NONNULL_END
