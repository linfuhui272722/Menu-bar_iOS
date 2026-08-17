// SPDX-License-Identifier: MIT
#import "MBAppMenuController.h"
#import "MBTheme.h"
#import "MBPrivateDecls.h"

@implementation MBAppMenuController {
    NSMenu *_apple;
    NSMenu *_app;
    NSString *_frontName;
}

- (instancetype)init {
    if ((self = [super init])) {
        _apple = [self _buildAppleMenu];
        _app = [self _buildAppMenu:nil];
    }
    return self;
}

- (NSMenu *)appleMenu { return _apple; }
- (NSMenu *)appMenu { return _app; }

- (NSMenu *)_buildAppleMenu {
    NSMenu *m = [[NSMenu alloc] initWithTitle:@"Apple"];
    [m addItemWithTitle:@"About This iPad" action:nil target:nil];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"System Settings…" action:@selector(_openSettings) target:self];
    [m addItemWithTitle:@"App Store…" action:nil target:nil];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Sleep" action:@selector(_sleep) target:self];
    [m addItemWithTitle:@"Restart…" action:@selector(_restart) target:self];
    [m addItemWithTitle:@"Shut Down…" action:@selector(_shutdown) target:self];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Lock Screen" action:@selector(_lockScreen) target:self];
    [m addItemWithTitle:@"Log Out…" action:@selector(_logout) target:self];
    return m;
}

- (NSMenu *)_buildAppMenu:(NSString *)name {
    NSMenu *m = [[NSMenu alloc] initWithTitle:(name ?: @"Finder")];
    [m addItemWithTitle:[NSString stringWithFormat:@"About %@", (name ?: @"Finder")] action:nil target:nil];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:[NSString stringWithFormat:@"Hide %@", (name ?: @"Finder")] action:@selector(_hideFront) target:self];
    [m addItemWithTitle:@"Hide Others" action:nil target:nil];
    [m addItemWithTitle:@"Show All" action:nil target:nil];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:[NSString stringWithFormat:@"Quit %@", (name ?: @"Finder")] action:@selector(_quitFront) target:self];
    return m;
}

- (void)setFrontmostApplication:(NSString *)bundleID name:(NSString *)name {
    _frontName = [name copy];
    _app = [self _buildAppMenu:name];
}

#pragma mark - Actions (SpringBoard private bridges)

- (void)_openSettings {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"App-prefs:"] options:@{} completionHandler:nil];
}
- (void)_sleep {
    Class c = MBClassNamed(@"SBBacklightController");
    if (c) { id b = [c performSelector:NSSelectorFromString(@"sharedInstance")];
        [b performSelector:NSSelectorFromString(@"turnOffScreenNow")]; }
}
- (void)_lockScreen { [self _sleep]; }
- (void)_restart {
    Class c = MBClassNamed(@"SBRestartController");
    if (c) { id b = [c performSelector:NSSelectorFromString(@"sharedInstance")];
        [b performSelector:NSSelectorFromString(@"reboot")]; }
}
- (void)_shutdown { [self _restart]; }
- (void)_logout { [self _lockScreen]; }
- (void)_hideFront {
    Class wc = MBClassNamed(@"SBMainWorkspace");
    if (wc) { id w = [wc performSelector:NSSelectorFromString(@"sharedInstance")];
        id app = [w performSelector:NSSelectorFromString(@"frontmostApplicationIdentity")];
        if (app) [w performSelector:NSSelectorFromString(@"deactivateAppWithBundleID:") withObject:app]; }
}
- (void)_quitFront { [self _hideFront]; }

@end
