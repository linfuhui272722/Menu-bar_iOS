// SPDX-License-Identifier: MIT
#import "AirPortExtra.h"
#import "MBTheme.h"
#import "MBPrivateDecls.h"

@interface AirPortExtra ()
@property (nonatomic, strong) UIView *signalView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL wifiOn;
@property (nonatomic, copy, nullable) NSString *ssid;
@property (nonatomic, assign) NSInteger bars;   // 0..4
@end

@implementation AirPortExtra

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 22, MBMenuBarHeight())])) {
        _signalView = [[UIView alloc] initWithFrame:CGRectMake(3, 2, 16, MBMenuBarHeight() - 4)];
        _signalView.backgroundColor = UIColor.clearColor;
        [self.menuExtraView addSubview:_signalView];
        self.menu = [self _buildMenu];
        [self _refresh];
        _timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self
                                                selector:@selector(_refresh) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)_refresh {
    Class wc = MBClassNamed(@"SBWiFiManager");
    if (wc) {
        id mgr = [wc performSelector:NSSelectorFromString(@"sharedInstance")];
        if (mgr) {
            _wifiOn = [[mgr valueForKey:@"wifiEnabled"] boolValue];
            _ssid = [mgr valueForKey:@"currentNetworkName"];
        }
    } else {
        _wifiOn = YES; _ssid = nil;
    }
    _bars = _wifiOn ? 3 : 0;
    [self _drawSignal];
}

- (void)_drawSignal {
    [_signalView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIColor *c = [MBTheme menuBarTextColor];
    CGFloat x = 0, y = MBMenuBarHeight() - 6;
    CGFloat widths[] = {3, 5, 7, 9};
    for (int i = 0; i < 4; i++) {
        CGFloat h = 2 + i * 2.5;
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(x, y - h, 3, h)];
        bar.backgroundColor = (i < _bars) ? c : [c colorWithAlphaComponent:0.25];
        [_signalView addSubview:bar];
        x += 4;
    }
}

- (NSMenu *)_buildMenu {
    NSMenu *m = [[NSMenu alloc] initWithTitle:@"Wi-Fi"];
    if (_ssid) {
        NSMenuItem *cur = [[NSMenuItem alloc] initWithTitle:_ssid action:nil target:nil];
        cur.enabled = NO;
        [m addItem:cur];
    } else {
        [m addItemWithTitle:@"Wi-Fi: Off" action:nil target:nil];
    }
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Turn Wi-Fi Off" action:@selector(_toggleWifi) target:self];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Open Network Preferences…" action:nil target:nil];
    return m;
}

- (void)_toggleWifi {
    Class wc = MBClassNamed(@"SBWiFiManager");
    if (!wc) return;
    id mgr = [wc performSelector:NSSelectorFromString(@"sharedInstance")];
    if (mgr) [mgr setValue:@(!_wifiOn) forKey:@"wifiEnabled"];
    [self _refresh];
}

- (void)dealloc { [_timer invalidate]; }

@end
