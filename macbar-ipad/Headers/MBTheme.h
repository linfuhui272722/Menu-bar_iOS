// SPDX-License-Identifier: MIT
// Shared look & constants for the menu bar. On macOS these come from
// HIToolbox (GetThemeMenuBarHeight, _HIMenuBarRequestVisibility). Here we
// hard-code the El Capitan menubar height (22pt) and compute against the
// current device status-bar height for the iPadOS overlay.
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// El Capitan menu bar thickness (== NSMenu.menuBarHeight == 22pt).
extern const CGFloat MBMenuBarHeightElCapitan;

/// Returns the menu bar thickness in points for the current device, mirroring
/// +[NSMenu menuBarHeight]. We keep macOS' 22pt and add the system status bar
/// height when overlaying.
CGFloat MBMenuBarHeight(void);

/// Theme colours. El Capitan menu bar is translucent light grey / dark when
/// dark. We follow UIUserInterfaceStyle at draw time.
@interface MBTheme : NSObject
+ (UIColor *)menuBarBackgroundColor;
+ (UIColor *)menuBarTextColor;
+ (UIColor *)menuHighlightColor;
+ (BOOL)isDark;
+ (void)menuBarThemeDidChange;   // notify all NSStatusBar instances
@end

NS_ASSUME_NONNULL_END
