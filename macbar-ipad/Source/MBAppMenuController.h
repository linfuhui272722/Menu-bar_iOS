// SPDX-License-Identifier: MIT
// MBAppMenuController — left side of the bar. Builds the Apple menu (About,
// Sleep, Lock, Restart, Shut Down, Log Out…) and the frontmost-app menu
// (Hide, Quit, Preferences…) mirroring AppKit's per-app NSApp menu template.
#import <UIKit/UIKit.h>
#import "MBCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBAppMenuController : NSObject
@property (nonatomic, readonly) NSMenu *appleMenu;
@property (nonatomic, readonly) NSMenu *appMenu;
- (void)setFrontmostApplication:(nullable NSString *)bundleID name:(nullable NSString *)name;
@end

NS_ASSUME_NONNULL_END
