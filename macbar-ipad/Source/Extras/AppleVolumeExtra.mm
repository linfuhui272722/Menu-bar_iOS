// SPDX-License-Identifier: MIT
#import "AppleVolumeExtra.h"
#import "MBTheme.h"
#import "MBPrivateDecls.h"

@interface AppleVolumeExtra ()
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, assign) float volume;
@end

@implementation AppleVolumeExtra

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 25, MBMenuBarHeight())])) {
        _icon = [[UIImageView alloc] initWithFrame:CGRectMake(3, 2, 18, MBMenuBarHeight() - 4)];
        _icon.contentMode = UIViewContentModeScaleAspectFit;
        [self.menuExtraView addSubview:_icon];
        _volume = 0.5;
        self.menu = [self _buildMenu];
        [self _refresh];
    }
    return self;
}

- (float)_currentVolume {
    Class vc = MBClassNamed(@"VolumeControl");
    if (vc) {
        id m = [vc performSelector:NSSelectorFromString(@"sharedInstance")];
        if (m) return [[m valueForKey:@"volume"] floatValue];
    }
    return _volume;
}

- (void)_setVolume:(float)v {
    _volume = v;
    Class vc = MBClassNamed(@"VolumeControl");
    if (vc) {
        id m = [vc performSelector:NSSelectorFromString(@"sharedInstance")];
        if (m) [m setValue:@(v) forKey:@"volume"];
    }
}

- (void)_refresh {
    _volume = [self _currentVolume];
    int idx = _volume <= 0.001 ? 1 : (_volume < 0.34 ? 2 : (_volume < 0.67 ? 3 : 4));
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    NSString *p = [b pathForResource:[NSString stringWithFormat:@"Volume%d", idx] ofType:@"pdf"
                        inDirectory:@"extras/Volume"];
    if (!p) p = [@"/var/jb/Library/MobileSubstrate/DynamicLibraries/MacBar.bundle/extras/Volume"
                stringByAppendingPathComponent:[NSString stringWithFormat:@"Volume%d.pdf", idx]];
    _icon.image = p ? [UIImage imageWithContentsOfFile:p] : [UIImage imageNamed:[NSString stringWithFormat:@"Volume%d", idx]];
}

- (NSMenu *)_buildMenu {
    NSMenu *m = [[NSMenu alloc] initWithTitle:@"Volume"];
    NSMenuItem *slider = [[NSMenuItem alloc] initWithTitle:@"Volume" action:nil target:nil];
    [m addItem:slider];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Mute" action:@selector(_mute) target:self];
    [m addItemWithTitle:@"Open Sound Preferences…" action:nil target:nil];
    return m;
}

- (void)_mute { [self _setVolume:0.0f]; [self _refresh]; }

@end
