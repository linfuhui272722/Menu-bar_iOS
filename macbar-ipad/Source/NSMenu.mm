// SPDX-License-Identifier: MIT
// UIKit rewrite of AppKit NSMenu + NSMenuItem.
// A pull-down menu is rendered in a dedicated UIWindow (MBMenuWindow) as a
// UITableView, anchored under the originating status-item button or app-menu.
#import "MBCore.h"
#import "MBTheme.h"

#pragma mark - NSMenuItem

@implementation NSMenuItem {
    BOOL _sep;
}
+ (instancetype)separatorItem {
    NSMenuItem *m = [self new];
    m->_sep = YES;
    return m;
}
- (instancetype)initWithTitle:(NSString *)title action:(SEL)action target:(id)target {
    if ((self = [super init])) { _title = [title copy]; _action = action; _target = target; _enabled = YES; }
    return self;
}
- (BOOL)separator { return _sep; }
- (void)setSeparator:(BOOL)s { _sep = s; }
@end

#pragma mark - NSMenu

@interface NSMenu ()
@property (nonatomic, strong) NSMutableArray<NSMenuItem *> *items;
@end

@implementation NSMenu

+ (CGFloat)menuBarHeight { return MBMenuBarHeight(); }
+ (BOOL)menuBarVisible {
    id w = [[NSUserDefaults standardUserDefaults] objectForKey:@"MBMenuBarVisible"];
    return w ? [w boolValue] : YES;
}
+ (void)setMenuBarVisible:(BOOL)visible {
    [[NSUserDefaults standardUserDefaults] setBool:visible forKey:@"MBMenuBarVisible"];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"MBMenuBarVisibilityDidChange" object:nil];
}

- (instancetype)initWithTitle:(NSString *)title {
    if ((self = [super init])) { _title = [title copy]; _items = [NSMutableArray array]; }
    return self;
}
- (NSArray<NSMenuItem *> *)itemArray { return [_items copy]; }
- (NSInteger)numberOfItems { return _items.count; }
- (void)addItem:(NSMenuItem *)item { [_items addObject:item]; }
- (NSMenuItem *)addItemWithTitle:(NSString *)title action:(SEL)action target:(id)target {
    NSMenuItem *m = [[NSMenuItem alloc] initWithTitle:title action:action target:target];
    [_items addObject:m];
    return m;
}
- (void)insertItem:(NSMenuItem *)item atIndex:(NSInteger)index {
    [_items insertObject:item atIndex:index];
}
- (void)removeItemAtIndex:(NSInteger)index {
    if (index < (NSInteger)_items.count) [_items removeObjectAtIndex:index];
}
@end
