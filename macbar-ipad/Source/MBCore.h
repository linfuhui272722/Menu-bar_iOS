// SPDX-License-Identifier: MIT
// MacBar — macOS menu bar ported to iPadOS.
//
// Class names / method names are intentionally identical to their AppKit
// counterparts (NSStatusBar, NSStatusItem, NSMenu, NSMenuItem, NSMenuExtra,
// NSStatusBarButton) so the public API surface matches macOS exactly; the
// implementations are rewritten on top of UIKit. NSStatusItem length
// semantics (fixed points vs NSVariableStatusItemLength) are preserved.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// NSStatusItem length sentinel — auto-sizing, exactly like AppKit.
extern const CGFloat NSVariableStatusItemLength;

/// Runtime helper: look up a private class by name, nil-safe.
extern Class MBClassNamed(NSString *name);

@class NSStatusBar, NSStatusItem, NSStatusBarButton, NSMenu, NSMenuItem, NSMenuExtra;

#pragma mark - NSStatusBar  (UIKit rewrite of AppKit NSStatusBar)

/// A container that lays out status items along the right edge of the menu bar.
/// Single system-wide instance, like +[NSStatusBar systemStatusBar].
@interface NSStatusBar : NSObject
+ (instancetype)systemStatusBar;
- (instancetype)init;
@property (nonatomic, readonly) CGFloat thickness;   // menu bar height
@property (nonatomic, readonly) BOOL isVertical;        // always NO (horizontal)
- (NSStatusItem *)statusItemWithLength:(CGFloat)length;
- (void)removeStatusItem:(NSStatusItem *)item;
// private (kept for parity)
- (NSStatusItem *)_statusItemWithLength:(CGFloat)length withPriority:(NSInteger)priority;
- (void)_removeStatusItem:(NSStatusItem *)item;
- (void)_adjustStatusItem:(NSStatusItem *)item;
- (void)_menuBarThemeDidChange:(id)n;
- (void)_menuBarTranslucencyDidChange:(id)n;
@end

#pragma mark - NSStatusItem  (UIKit rewrite of AppKit NSStatusItem)

@interface NSStatusItem : NSObject
- (instancetype)_initInStatusBar:(NSStatusBar *)statusBar
                         withLength:(CGFloat)length
                        withPriority:(NSInteger)priority;
@property (nonatomic, readonly) NSStatusBar *statusBar;
@property (nonatomic) CGFloat length;                  // points, or NSVariableStatusItemLength
@property (nonatomic, strong, nullable) NSString *title;
@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, strong, nullable) UIImage *alternateImage;
@property (nonatomic) BOOL highlightMode;
@property (nonatomic) BOOL enabled;
@property (nonatomic, strong, nullable) NSMenu *menu; // pull-down menu
@property (nonatomic, strong, nullable) UIView *view;  // custom view override
@property (nonatomic, readonly) NSStatusBarButton *button;
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, nullable) SEL action;
- (void)sendActionOn:(NSUInteger)mask;            // no-op parity (AppKit)
- (void)_adjustLength;
@end

#pragma mark - NSStatusBarButton  (UIKit rewrite of AppKit NSStatusBarButton)

@interface NSStatusBarButton : UIButton
- (instancetype)initWithFrame:(CGRect)frame inStatusBar:(NSStatusBar *)statusBar;
@property (nonatomic, weak, nullable) NSStatusItem *statusItem;
@end

#pragma mark - NSMenuExtra  (UIKit rewrite of AppKit NSMenuExtra)

/// Base class for a dynamically-loadable right-side item, exactly like the
/// macOS .menu NSPrincipalClass subclasses (AppleClockExtra, AirPortExtra...).
@interface NSMenuExtra : NSObject
@property (nonatomic) CGFloat menuExtraWidth;   // from Info.plist
@property (nonatomic, strong) UIView *menuExtraView;
@property (nonatomic, strong, nullable) NSMenu *menu;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)menuWillOpen;
- (void)menuDidClose;
@end

#pragma mark - NSMenuItem / NSMenu  (UIKit rewrite of AppKit NSMenu/NSMenuItem)

@interface NSMenuItem : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, strong, nullable) UIImage *image;
@property (nonatomic, strong, nullable) NSMenu *submenu;
@property (nonatomic, weak, nullable) id target;
@property (nonatomic, nullable) SEL action;
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL separator;
@property (nonatomic) NSInteger state;   ///< 0=off,1=on,2=mixed (NSOnState/NSOffState parity)
@property (nonatomic, copy, nullable) NSString *keyEquivalent;
+ (instancetype)separatorItem;
- (instancetype)initWithTitle:(NSString *)title action:(nullable SEL)action target:(nullable id)target;
@end

@interface NSMenu : NSObject
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, strong, readonly) NSArray<NSMenuItem *> *itemArray;
- (instancetype)initWithTitle:(NSString *)title;
- (void)addItem:(NSMenuItem *)item;
- (NSMenuItem *)addItemWithTitle:(NSString *)title action:(nullable SEL)action target:(nullable id)target;
- (void)insertItem:(NSMenuItem *)item atIndex:(NSInteger)index;
- (void)removeItemAtIndex:(NSInteger)index;
- (NSInteger)numberOfItems;
+ (CGFloat)menuBarHeight;
+ (BOOL)menuBarVisible;
+ (void)setMenuBarVisible:(BOOL)visible;
@end

NS_ASSUME_NONNULL_END
