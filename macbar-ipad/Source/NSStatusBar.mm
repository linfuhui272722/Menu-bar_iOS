// SPDX-License-Identifier: MIT
// UIKit rewrite of AppKit NSStatusBar + theme/height helpers (HIToolbox parity).
#import "MBCore.h"
#import "MBTheme.h"
#import <objc/runtime.h>

const CGFloat MBMenuBarHeightElCapitan = 22.0f;

static CGFloat MBStatusBarPadHeight(void) {
    // iPadOS: the OS status bar (time/wifi/battery) is ~ the safe-area top.
    UIWindow *w = [UIApplication sharedApplication].windows.firstObject;
    UIEdgeInsets sf = w.safeAreaInsets;
    return sf.top > 0 ? sf.top : 20.0f;
}

CGFloat MBMenuBarHeight(void) {
    // On macOS NSMenu.menuBarHeight == 22. On iPadOS we sit *below* the system
    // status bar, so the bar itself keeps 22pt height.
    return MBMenuBarHeightElCapitan;
}

#pragma mark - MBTheme

@implementation MBTheme
+ (BOOL)isDark {
    UIWindow *w = [UIApplication sharedApplication].windows.firstObject;
    return w.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
}
+ (UIColor *)menuBarBackgroundColor {
    if ([self isDark]) {
        return [UIColor colorWithWhite:0.10 alpha:0.78];
    }
    return [UIColor colorWithWhite:1.0 alpha:0.55];
}
+ (UIColor *)menuBarTextColor {
    return [self isDark] ? [UIColor whiteColor] : [UIColor blackColor];
}
+ (UIColor *)menuHighlightColor {
    return [UIColor colorWithRed:0.20 green:0.46 blue:0.94 alpha:1.0];
}
+ (void)menuBarThemeDidChange {
    [[NSStatusBar systemStatusBar] _menuBarThemeDidChange:nil];
}
@end

#pragma mark - NSStatusBar

@interface NSStatusBar ()
@property (nonatomic, strong) NSMutableArray<NSStatusItem *> *itemArray;
@end

@implementation NSStatusBar

+ (instancetype)systemStatusBar {
    static NSStatusBar *s;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [[self alloc] init]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        _itemArray = [NSMutableArray array];
    }
    return self;
}

- (CGFloat)thickness {
    return MBMenuBarHeight();
}

- (BOOL)isVertical { return NO; }

- (NSStatusItem *)statusItemWithLength:(CGFloat)length {
    return [self _statusItemWithLength:length withPriority:0];
}

- (NSStatusItem *)_statusItemWithLength:(CGFloat)length withPriority:(NSInteger)priority {
    NSStatusItem *it = [[NSStatusItem alloc] _initInStatusBar:self
                                                    withLength:length
                                                   withPriority:priority];
    if (it) [self.itemArray addObject:it];
    return it;
}

- (void)removeStatusItem:(NSStatusItem *)item {
    [self _removeStatusItem:item];
}

- (void)_removeStatusItem:(NSStatusItem *)item {
    [self.itemArray removeObject:item];
    [self _adjustStatusItem:nil];
}

- (void)_adjustStatusItem:(NSStatusItem *)item {
    // The hosting MBMenuBarView observes itemArray; trigger a relayout.
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"MBStatusBarItemsDidChange" object:self];
}

- (void)_menuBarThemeDidChange:(id)n {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"MBMenuBarThemeDidChange" object:self];
}
- (void)_menuBarTranslucencyDidChange:(id)n {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"MBMenuBarThemeDidChange" object:self];
}

@end
