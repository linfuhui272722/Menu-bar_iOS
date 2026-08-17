// SPDX-License-Identifier: MIT
// MBVolumeHooks — route iOS hardware volume changes to the ported AppleVolumeExtra,
// mirroring how macOS Volume.menu reacts to the system volume (the AppKit
// NSMenuExtra observes a distributed volume notification).
#import "MBCore.h"
#import "MBTheme.h"

// AVAudioSession volume-change: iOS posts no public notification, but a
// SystemVolumeDidChange coremedia notification exists. We listen to it.
@interface MBVolumeHooks : NSObject
@end

@implementation MBVolumeHooks
+ (void)load {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_volChanged:)
                                                 name:@"SystemVolumeDidChange"
                                               object:nil];
}
+ (void)_volChanged:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"MBVolumeDidChange" object:nil userInfo:n.userInfo];
}
@end
