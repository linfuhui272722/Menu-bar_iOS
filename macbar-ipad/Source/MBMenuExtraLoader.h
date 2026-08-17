// SPDX-License-Identifier: MIT
// MBMenuExtraLoader — ports SystemUIServer's load logic (Autoload.plist +
// CoreMenuExtraAddMenuExtra / Get / Remove).
#import "MBCore.h"

NS_ASSUME_NONNULL_BEGIN

@interface MBMenuExtraLoader : NSObject
+ (instancetype)sharedLoader;
- (void)loadAutoloadedExtras;
- (NSStatusItem *)addMenuExtraOfClass:(Class)cls width:(CGFloat)width;
- (void)removeMenuExtra:(NSStatusItem *)item;
@end

NS_ASSUME_NONNULL_END
