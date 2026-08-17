// SPDX-License-Identifier: MIT
// Forward declarations of private iOS classes used via objc_getClass so the
// SDK headers (which lack them) do not need to be patched. Everything is
// resolved at runtime; missing classes degrade gracefully to nil.
#import <Foundation/Foundation.h>

// SpringBoard front-most app (SBMainWorkspace).
@interface SBMainWorkspace : NSObject
+ (instancetype)sharedInstance;
- (nullable id)frontmostApplicationIdentity;
- (nullable NSString *)bundleIdentifierForApplicationIdentity:(id)identity;
- (nullable NSString *)displayIdentifierForApplicationIdentity:(id)identity;
@end

// Generic SBApplication.
@interface SBApplication : NSObject
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;
@property (nonatomic, copy, nullable) NSString *displayName;
- (nullable UIImage *)icon;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (nullable SBApplication *)applicationWithBundleIdentifier:(NSString *)bid;
@end

// Rotation / orientation lock (SpringBoard).
@interface SBDeviceOrientationLockManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, readonly) BOOL isLocked;
- (void)lock;
- (void)unlock;
@end

// WiFi (MobileWiFi / SpringBoardUI).
@interface SBWiFiManager : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, readonly) BOOL wifiEnabled;
@property (nonatomic, readonly, nullable) NSString *currentNetworkName;
- (void)setWiFiEnabled:(BOOL)enabled;
@end

// Volume (MediaController / AVAudioSession private route).
@interface VolumeControl : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, readonly) float volume;       // 0..1
- (void)setVolume:(float)v;
@end
