// SPDX-License-Identifier: MIT
// MBSpringBoardHooks — tweak entry. Loaded by ElleKit (the rootless,
// MobileSubstrate-compatible hooking library) into SpringBoard.
// ElleKit re-exports MSHookMessageEx, so the same symbol name works; this
// project deliberately stays Logos-free so it builds with a plain clang
// toolchain on Linux.
#import "MBCore.h"
#import "MBTheme.h"
#import "MBMenuBarWindow.h"
#import "MBMenuBarView.h"
#import "MBMenuExtraLoader.h"
#import "MBPrivateDecls.h"
#import <objc/runtime.h>

// ElleKit hook primitive (resolved at load time on device; weakly referenced
// here so the link succeeds in a cross-compile environment without libsubstrate).
extern "C" void MSHookMessageEx(Class cls, SEL sel, IMP imp, IMP *orig) __attribute__((weak));

// Notification posted by SpringBoard when the front-most app changes.
static NSString *const kSBFrontmostChangedNotification = @"SBFrontmostApplicationChangedNotification";

@interface MBSpringBoardHooks : NSObject
@end

@implementation MBSpringBoardHooks

+ (void)load {
    // Defer real setup to the first SpringBoard runloop tick.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_appStateChanged:)
                                                 name:kSBFrontmostChangedNotification object:nil];
}

- (void)_appStateChanged:(NSNotification *)n {
    NSString *bid = n.userInfo[@"bundleIdentifier"];
    NSString *name = n.userInfo[@"displayName"];
    UIImage *icon = n.userInfo[@"icon"];
    [[MBMenuBarView sharedBar] updateFrontmostApplication:bid displayName:name icon:icon];
}

@end

// ---- hooks via MSHookMessageEx (parity with Theos %hook) ----

// SBMainWorkspace applicationDidActivate: → refresh front-most app menu.
static void (*orig_SBMainWorkspace_applicationDidActivate)(id, SEL, id);
static void hook_SBMainWorkspace_applicationDidActivate(id self, SEL _cmd, id app) {
    orig_SBMainWorkspace_applicationDidActivate(self, _cmd, app);
    NSString *bid = [app respondsToSelector:@selector(bundleIdentifier)] ? [app bundleIdentifier] : nil;
    NSString *name = [app respondsToSelector:@selector(displayName)] ? [app displayName] : bid;
    [[MBMenuBarView sharedBar] updateFrontmostApplication:bid displayName:name icon:nil];
}

// SpringBoard -applicationDidFinishLaunching: → install the menu bar.
static void (*orig_SBAppDelegate_didFinishLaunching)(id, SEL, id);
static void hook_SBAppDelegate_didFinishLaunching(id self, SEL _cmd, id app) {
    orig_SBAppDelegate_didFinishLaunching(self, _cmd, app);
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *host = [UIApplication sharedApplication].windows.firstObject;
        MBMenuBarWindow *w = [MBMenuBarWindow sharedWindow];
        [w installInHost:host];
        [w show];
        [[MBMenuExtraLoader sharedLoader] loadAutoloadedExtras];
    });
}

static void _installHooks(void) {
    Class mw = MBClassNamed(@"SBMainWorkspace");
    if (mw && MSHookMessageEx) {
        MSHookMessageEx(mw, @selector(applicationDidActivate:),
                        (IMP)hook_SBMainWorkspace_applicationDidActivate,
                        (IMP *)&orig_SBMainWorkspace_applicationDidActivate);
    }
    // SpringBoard's principal delegate class is SBAppDelegate / SBApplication
    Class sbAd = MBClassNamed(@"SBAppDelegate");
    if (!sbAd) sbAd = MBClassNamed(@"UIApplication");
    if (sbAd && MSHookMessageEx) {
        MSHookMessageEx(sbAd, @selector(applicationDidFinishLaunching:),
                        (IMP)hook_SBAppDelegate_didFinishLaunching,
                        (IMP *)&orig_SBAppDelegate_didFinishLaunching);
    }
}

// MobileSubstrate constructor — runs at load time, the Theos %ctor equivalent.
__attribute__((constructor)) static void MacBarCtor(void) {
    // Also boot on apps that aren't SBAppDelegate (e.g. when injected into a
    // hosted app); the host window installs from the bar's own +load observer.
    dispatch_async(dispatch_get_main_queue(), ^{ _installHooks(); });
}
