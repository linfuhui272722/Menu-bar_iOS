// SPDX-License-Identifier: MIT
#import "MBMenuBarView.h"
#import "MBTheme.h"
#import "MBMenuWindow.h"
#import "MBAppMenuController.h"
#import "MBMenuExtraLoader.h"

@interface MBMenuBarView ()
@property (nonatomic, strong) UIButton *appleMenuButton;
@property (nonatomic, strong) UIButton *appNameButton;
@property (nonatomic, strong) UIImageView *appIcon;
@property (nonatomic, strong) UIView *leftContainer;
@property (nonatomic, strong) UIView *rightContainer;
@property (nonatomic, strong) MBAppMenuController *appMenu;
@property (nonatomic, copy) NSString *frontApp;
@property (nonatomic, strong) NSMutableArray<NSStatusItem *> *items;
@end

@implementation MBMenuBarView

+ (instancetype)sharedBar {
    static MBMenuBarView *b; static dispatch_once_t t;
    dispatch_once(&t, ^{ b = [[self alloc] init]; });
    return b;
}

- (instancetype)init {
    CGRect f = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, MBMenuBarHeight());
    if ((self = [super initWithFrame:f])) {
        self.backgroundColor = [MBTheme menuBarBackgroundColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.15;
        self.layer.shadowRadius = 2;
        self.layer.shadowOffset = CGSizeMake(0, 1);
        _items = [NSMutableArray array];
        [self _setupLeft];
        [self _setupRight];
        [self _observe];
    }
    return self;
}

- (void)_setupLeft {
    _leftContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, MBMenuBarHeight())];
    _leftContainer.backgroundColor = UIColor.clearColor;
    [self addSubview:_leftContainer];

    _appleMenuButton = [self _barButton:@"⌘"];
    _appleMenuButton.frame = CGRectMake(0, 0, 26, MBMenuBarHeight());
    [_appleMenuButton setTitle:@"" forState:UIControlStateNormal];
    _appleMenuButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_leftContainer addSubview:_appleMenuButton];

    _appIcon = [[UIImageView alloc] initWithFrame:CGRectMake(28, 2, MBMenuBarHeight()-4, MBMenuBarHeight()-4)];
    _appIcon.contentMode = UIViewContentModeScaleAspectFit;
    _appIcon.hidden = YES;
    [_leftContainer addSubview:_appIcon];

    _appNameButton = [self _barButton:@"Finder"];
    _appNameButton.frame = CGRectMake(48, 0, 170, MBMenuBarHeight());
    _appNameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [_leftContainer addSubview:_appNameButton];

    _appMenu = [MBAppMenuController new];
    [_appleMenuButton addTarget:self action:@selector(_showAppleMenu:) forControlEvents:UIControlEventTouchUpInside];
    [_appNameButton addTarget:self action:@selector(_showAppMenu:) forControlEvents:UIControlEventTouchUpInside];
}

- (UIButton *)_barButton:(NSString *)t {
    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:t forState:UIControlStateNormal];
    b.titleLabel.font = [UIFont systemFontOfSize:13];
    [b setTitleColor:[MBTheme menuBarTextColor] forState:UIControlStateNormal];
    b.backgroundColor = UIColor.clearColor;
    return b;
}

- (void)_setupRight {
    _rightContainer = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width - 300, 0, 300, MBMenuBarHeight())];
    _rightContainer.backgroundColor = UIColor.clearColor;
    _rightContainer.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_rightContainer];
}

- (void)_observe {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_itemsChanged)
                                                 name:@"MBStatusBarItemsDidChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_themeChanged)
                                                 name:@"MBMenuBarThemeDidChange" object:nil];
}

- (void)_themeChanged {
    self.backgroundColor = [MBTheme menuBarBackgroundColor];
    [_appleMenuButton setTitleColor:[MBTheme menuBarTextColor] forState:UIControlStateNormal];
    [_appNameButton setTitleColor:[MBTheme menuBarTextColor] forState:UIControlStateNormal];
    [self reloadStatusItems];
}

- (void)_itemsChanged { [self reloadStatusItems]; }

- (void)reloadStatusItems {
    for (UIView *v in _rightContainer.subviews) [v removeFromSuperview];
    NSStatusBar *sb = [NSStatusBar systemStatusBar];
    NSArray *all = [sb valueForKey:@"itemArray"] ?: @[];
    _items = [all mutableCopy];
    // Lay out right-to-left.
    CGFloat x = _rightContainer.bounds.size.width;
    for (NSStatusItem *it in [_items reverseObjectEnumerator]) {
        UIView *v = it.view ?: it.button;
        if (!v) continue;
        CGFloat w = it.length == NSVariableStatusItemLength ? v.bounds.size.width : it.length;
        if (w <= 0) w = v.bounds.size.width;
        [v removeFromSuperview];
        v.frame = CGRectMake(x - w, 0, w, MBMenuBarHeight());
        [_rightContainer addSubview:v];
        x -= w;
    }
}

- (void)updateFrontmostApplication:(NSString *)bundleID displayName:(NSString *)name icon:(UIImage *)icon {
    _frontApp = [bundleID copy];
    [_appNameButton setTitle:(name ?: @"SpringBoard") forState:UIControlStateNormal];
    _appIcon.image = icon;
    _appIcon.hidden = (icon == nil);
    [_appMenu setFrontmostApplication:bundleID name:name];
}

- (void)_showAppleMenu:(UIButton *)b {
    CGRect r = [b.superview convertRect:b.frame toView:self];
    [self presentMenu:[_appMenu appleMenu] fromRect:r];
}

- (void)_showAppMenu:(UIButton *)b {
    CGRect r = [b.superview convertRect:b.frame toView:self];
    [self presentMenu:[_appMenu appMenu] fromRect:r];
}

- (void)presentMenu:(NSMenu *)menu fromRect:(CGRect)rect {
    MBMenuWindow *w = [[MBMenuWindow alloc] initWithMenu:menu origin:rect];
    (void)w;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

@end
