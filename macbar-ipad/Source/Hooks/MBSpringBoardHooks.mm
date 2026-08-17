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

// Install the menu bar: find the host window, create the menu bar window,
// attach it, show it, and load the Menu Extras. Safe to call repeatedly.
+ (void)installMenuBarNow {
    UIWindow *host = [UIApplication sharedApplication].windows.firstObject;
    if (!host || host.bounds.size.width < 10.0f) {
        // Too early (SpringBoard still launching) — retry shortly.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [self installMenuBarNow]; });
        return;
    }
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        MBMenuBarWindow *w = [MBMenuBarWindow sharedWindow];
        [w installInHost:host];
        [w show];
        [[MBMenuExtraLoader sharedLoader] loadAutoloadedExtras];
    });
}
@end

// ---- hooks via MSHookMessageEx (parity with Theos %hook) ----

// SBMainWorkspace applicationDidActivate: → refresh front-most app menu.
static void (*orig_SBMainWorkspace_applicationDidActivate)(id, SEL, id);
static void hook_SBMainWorkspace_applicationDidActivate(id self, SEL _cmd, id app) {
    if (orig_SBMainWorkspace_applicationDidActivate)
        orig_SBMainWorkspace_applicationDidActivate(self, _cmd, app);
    NSString *bid = [app respondsToSelector:@selector(bundleIdentifier)] ? [app bundleIdentifier] : nil;
    NSString *name = [app respondsToSelector:@selector(displayName)] ? [app displayName] : bid;
    [[MBMenuBarView sharedBar] updateFrontmostApplication:bid displayName:name icon:nil];
}

// SpringBoard -applicationDidFinishLaunching: → install the menu bar (if it
// fires; on some iOS versions the hook is installed after launch has run, so
// _installHooks also installs the bar directly — this is just a bonus path).
static void (*orig_SBAppDelegate_didFinishLaunching)(id, SEL, id);
static void hook_SBAppDelegate_didFinishLaunching(id self, SEL _cmd, id app) {
    if (orig_SBAppDelegate_didFinishLaunching)
        orig_SBAppDelegate_didFinishLaunching(self, _cmd, app);
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBSpringBoardHooks installMenuBarNow];
    });
}

static void _installHooks(void) {
    if (!MSHookMessageEx) return;  // ElleKit not loaded — nothing to do

    // Only hook methods that actually exist on the class; hooking a
    // non-existent selector makes MSHookMessageEx add the method and leaves
    // the saved orig as NULL, so the trampoline must guard for that.
    Class mw = MBClassNamed(@"SBMainWorkspace");
    if (mw && class_getInstanceMethod(mw, @selector(applicationDidActivate:))) {
        MSHookMessageEx(mw, @selector(applicationDidActivate:),
                        (IMP)hook_SBMainWorkspace_applicationDidActivate,
                        (IMP *)&orig_SBMainWorkspace_applicationDidActivate);
    }
    // SpringBoard's principal delegate class is SBAppDelegate; fall back to
    // SBApplication (the UIApplication subclass SpringBoard uses). Hooking
    // UIApplication itself is avoided — it would add a method it shouldn't own.
    Class sbAd = MBClassNamed(@"SBAppDelegate");
    if (!sbAd) sbAd = MBClassNamed(@"SBApplication");
    if (!sbAd) sbAd = MBClassNamed(@"SpringBoard");
    if (sbAd && class_getInstanceMethod(sbAd, @selector(applicationDidFinishLaunching:))) {
        MSHookMessageEx(sbAd, @selector(applicationDidFinishLaunching:),
                        (IMP)hook_SBAppDelegate_didFinishLaunching,
                        (IMP *)&orig_SBAppDelegate_didFinishLaunching);
    }

    // Always try to install the bar directly. The launch hook above may never
    // fire (installed after launch already ran), so don't depend on it.
    [MBSpringBoardHooks installMenuBarNow];
}

// MobileSubstrate constructor — runs at load time, the Theos %ctor equivalent.
__attribute__((constructor)) static void MacBarCtor(void) {
    // Also boot on apps that aren't SBAppDelegate (e.g. when injected into a
    // hosted app); the host window installs from the bar's own +load observer.
    dispatch_async(dispatch_get_main_queue(), ^{ _installHooks(); });
}
