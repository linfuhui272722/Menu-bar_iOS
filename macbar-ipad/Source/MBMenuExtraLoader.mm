// SPDX-License-Identifier: MIT
// MBMenuExtraLoader — ports SystemUIServer's load logic.
//
// On macOS, SystemUIServer reads Autoload.plist and for each candidate calls
// a _xxxCanLoad selector, then CoreMenuExtraAddMenuExtra loads the .menu's
// NSPrincipalClass (an NSMenuExtra subclass). We replicate the same plist
// and the same dispatch-by-selector pattern, with a map from .menu path to
// the built-in NSMenuExtra subclass we ported (AppleClockExtra, BatteryExtra,
// AirPortExtra, AppleVolumeExtra, ...).
#import "MBMenuExtraLoader.h"
#import "MBCore.h"
#import "MBTheme.h"

// Ported extras (their macOS NSPrincipalClass names):
#import "Extras/AppleClockExtra.h"
#import "Extras/BatteryExtra.h"
#import "Extras/AirPortExtra.h"
#import "Extras/AppleVolumeExtra.h"
#import "Extras/MBRotationLockExtra.h"

@interface MBMenuExtraLoader () {
    NSMutableArray<NSStatusItem *> *_items;
    NSDictionary<NSString *, NSString *> *_canLoadSelectors;
    NSDictionary<NSString *, Class> *_classMap;
}
@end

@implementation MBMenuExtraLoader

+ (instancetype)sharedLoader {
    static MBMenuExtraLoader *s; static dispatch_once_t t;
    dispatch_once(&t, ^{ s = [self new]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        _items = [NSMutableArray array];
        // Map from .menu basename -> NSMenuExtra subclass (ported).
        _classMap = @{
            @"Clock.menu"     : [AppleClockExtra class],
            @"Battery.menu"   : [BatteryExtra class],
            @"AirPort.menu"   : [AirPortExtra class],
            @"Volume.menu"    : [AppleVolumeExtra class],
            @"User.menu"      : [NSNull null],
        };
        // The exact selectors from SystemUIServer Autoload.plist.
        _canLoadSelectors = @{
            @"Clock.menu"     : @"_clockCanLoad",
            @"Battery.menu"   : @"_batteryCanLoad",
            @"AirPort.menu"   : @"_airportCanLoad",
            @"Volume.menu"    : @"_volumeCanLoad",
            @"User.menu"      : @"_userCanLoad",
        };
    }
    return self;
}

/// Mirrors the per-candidate can-load check used by SystemUIServer.
- (BOOL)performCanLoadSelector:(NSString *)selName {
    if (selName.length == 0) return YES;
    SEL s = NSSelectorFromString(selName);
    if (![self respondsToSelector:s]) {
        // Unknown selector: default to loading (parity with a missing check).
        return YES;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [self performSelector:s] ? YES : NO;
#pragma clang diagnostic pop
}

// The real SystemUIServer can-load selectors (here all return YES on iPadOS,
// where the underlying capability — battery, wifi, audio — is always present).
- (BOOL)_clockCanLoad { return YES; }
- (BOOL)_batteryCanLoad {
    UIDevice *d = [UIDevice currentDevice];
    d.batteryMonitoringEnabled = YES;
    return d.batteryState != UIDeviceBatteryStateUnknown;
}
- (BOOL)_airportCanLoad { return YES; }
- (BOOL)_volumeCanLoad { return YES; }
- (BOOL)_userCanLoad { return YES; }

- (void)loadAutoloadedExtras {
    // Read the verbatim Autoload.plist bundled from SystemUIServer.
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    NSString *path = [b pathForResource:@"Autoload" ofType:@"plist"];
    if (!path) {
        path = @"/var/jb/Library/MobileSubstrate/DynamicLibraries/MacBar.bundle/Autoload.plist";
    }
    NSArray *autoload = [NSArray arrayWithContentsOfFile:path];
    for (NSDictionary *e in autoload) {
        NSString *mPath = e[@"path"];
        NSString *base = mPath.lastPathComponent;
        id mapped = _classMap[base];
        Class cls = [mapped isKindOfClass:[NSNull class]] ? Nil : (Class)mapped;
        NSString *selName = e[@"method"];
        if (![self performCanLoadSelector:selName]) continue;
        if (!cls) continue;
        // NSMenuExtraWidth is normally in each .menu's Info.plist; the ported
        // subclasses hard-code their own width (clock=140, volume=25...).
        NSStatusItem *item = [self addMenuExtraOfClass:cls width:NSVariableStatusItemLength];
        if (item) [_items addObject:item];
    }
}

- (NSStatusItem *)addMenuExtraOfClass:(Class)cls width:(CGFloat)width {
    NSMenuExtra *extra = [[cls alloc] initWithFrame:CGRectMake(0, 0, width, MBMenuBarHeight())];
    NSStatusItem *item = [[NSStatusBar systemStatusBar] statusItemWithLength:width];
    item.view = extra.menuExtraView;
    item.menu = extra.menu;
    return item;
}

- (void)removeMenuExtra:(NSStatusItem *)item {
    [[NSStatusBar systemStatusBar] removeStatusItem:item];
    [_items removeObject:item];
}

@end
