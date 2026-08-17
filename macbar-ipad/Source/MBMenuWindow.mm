// SPDX-License-Identifier: MIT
// Pull-down menu window: presents an NSMenu under a status item / app-menu.
// This is the UIKit equivalent of AppKit's popUpContextMenu: machinery
// (NSMenuView / _NSMenuWindow).
#import "MBCore.h"
#import "MBTheme.h"
#import "MBMenuWindow.h"

@interface MBMenuTableView : UITableView <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, copy) void (^dismiss)(void);
@end

@implementation MBMenuTableView

- (instancetype)initWithMenu:(NSMenu *)menu {
    self = [super initWithFrame:CGRectZero style:UITableViewStylePlain];
    if (self) {
        _menu = menu;
        self.dataSource = self;
        self.delegate = self;
        self.scrollEnabled = NO;
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.backgroundColor = [MBTheme menuBarBackgroundColor];
        self.layer.cornerRadius = 6;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 6;
        self.layer.shadowOffset = CGSizeZero;
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)s {
    return self.menu.numberOfItems;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    NSMenuItem *m = self.menu.itemArray[ip.row];
    return m.separator ? 9.0 : 32.0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NSMenuItem *m = self.menu.itemArray[ip.row];
    if (m.separator) {
        UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(8, 4, tv.bounds.size.width - 16, 1)];
        sep.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.4];
        [c.contentView addSubview:sep];
        c.backgroundColor = UIColor.clearColor;
        c.selectionStyle = UITableViewCellSelectionStyleNone;
        return c;
    }
    UITableViewCell *c = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    c.backgroundColor = UIColor.clearColor;
    c.textLabel.text = m.title;
    c.textLabel.textColor = [MBTheme menuBarTextColor];
    c.textLabel.font = [UIFont systemFontOfSize:14];
    c.selectionStyle = UITableViewCellSelectionStyleDefault;
    c.textLabel.enabled = m.enabled;
    if (m.state == 1) {
        c.accessoryType = UITableViewCellAccessoryCheckmark;
    } else if (m.state == 2) {
        c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if (m.image) c.imageView.image = m.image;
    return c;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    NSMenuItem *m = self.menu.itemArray[ip.row];
    if (!m.enabled) return;
    if (m.submenu) {
        // Open nested submenu to the right — simple recursion via notification.
        [[NSNotificationCenter defaultCenter]
            postNotificationName:@"MBSubMenuRequested"
                            object:m.submenu
                          userInfo:@{@"origin": [NSValue valueWithCGRect:self.frame]}];
        return;
    }
    if (m.target && m.action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [m.target performSelector:m.action withObject:m];
#pragma clang diagnostic pop
    }
    if (self.dismiss) self.dismiss();
}

@end

@interface MBMenuWindow ()
@property (nonatomic, strong) MBMenuTableView *table;
@property (nonatomic, strong) UIView *dimView;
@end

@implementation MBMenuWindow

- (instancetype)initWithMenu:(NSMenu *)menu origin:(CGRect)origin {
    UIWindow *host = [UIApplication sharedApplication].windows.firstObject;
    self = [super initWithFrame:host.bounds];
    if (self) {
        self.windowLevel = UIWindowLevelAlert + 10;
        self.backgroundColor = UIColor.clearColor;
        self.hidden = NO;
        _table = [[MBMenuTableView alloc] initWithMenu:menu];
        // size to fit content
        [self addSubview:_table];
        // compute frame under origin
        CGFloat maxW = 220.0;
        [self layoutMenu:maxW origin:origin hostBounds:host.bounds];
        __weak typeof(self) ws = self;
        _table.dismiss = ^{ [ws close]; };
    }
    return self;
}

- (void)layoutMenu:(CGFloat)maxW origin:(CGRect)origin hostBounds:(CGRect)host {
    // precompute height
    CGFloat h = 0;
    for (NSMenuItem *m in self.table.menu.itemArray) h += m.separator ? 9.0 : 32.0;
    CGFloat w = MIN(maxW, host.size.width - 16);
    CGFloat x = MAX(8, MIN(origin.origin.x, host.size.width - w - 8));
    CGFloat y = origin.origin.y + origin.size.height;
    if (y + h > host.size.height - 8) y = MAX(8, origin.origin.y - h);
    self.table.frame = CGRectMake(x, y, w, h);
}

- (void)close {
    [self removeFromSuperview];
    self.hidden = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)t withEvent:(UIEvent *)e {
    CGPoint p = [t.anyObject locationInView:self];
    if (!CGRectContainsPoint(self.table.frame, p)) [self close];
}

@end
