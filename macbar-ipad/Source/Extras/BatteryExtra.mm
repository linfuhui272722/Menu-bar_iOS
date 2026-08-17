// SPDX-License-Identifier: MIT
#import "BatteryExtra.h"
#import "MBTheme.h"

@interface BatteryExtra ()
@property (nonatomic, strong) UIImageView *icon;
@property (nonatomic, strong) UILabel *pctLabel;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation BatteryExtra

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 40, MBMenuBarHeight())])) {
        UIDevice *d = [UIDevice currentDevice];
        d.batteryMonitoringEnabled = YES;

        _icon = [[UIImageView alloc] initWithFrame:CGRectMake(4, 2, 16, MBMenuBarHeight() - 4)];
        _icon.contentMode = UIViewContentModeScaleAspectFit;
        [self.menuExtraView addSubview:_icon];

        _pctLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 0, 16, MBMenuBarHeight())];
        _pctLabel.font = [UIFont systemFontOfSize:11];
        _pctLabel.textColor = [MBTheme menuBarTextColor];
        _pctLabel.textAlignment = NSTextAlignmentCenter;
        [self.menuExtraView addSubview:_pctLabel];

        self.menu = [self _buildMenu];
        [self _tick];
        _timer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self
                                                selector:@selector(_tick) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)_tick {
    UIDevice *d = [UIDevice currentDevice];
    float v = d.batteryLevel;            // 0..1, -1 unknown
    BOOL charging = (d.batteryState == UIDeviceBatteryStateCharging || d.batteryState == UIDeviceBatteryStateFull);
    if (v < 0) { _pctLabel.text = @"--"; _icon.image = nil; return; }
    _pctLabel.text = [NSString stringWithFormat:@"%d%%", (int)(v * 100)];
    NSString *res = charging ? @"BatteryCharging" : (v < 0.2 ? @"BatteryEmpty" : @"BatteryLevelCapB-M");
    _icon.image = [self _imageNamed:res];
}

- (UIImage *)_imageNamed:(NSString *)n {
    // El Capitan art assets are PDFs; UIImage can decode them via CGPDFDocument.
    NSBundle *b = [NSBundle bundleForClass:[self class]];
    NSString *p = [b pathForResource:n ofType:@"pdf"
                        inDirectory:@"extras/Battery"];
    if (!p) p = [@"/var/jb/Library/MobileSubstrate/DynamicLibraries/MacBar.bundle/extras/Battery" stringByAppendingPathComponent:[n stringByAppendingString:@".pdf"]];
    return p ? [UIImage imageWithContentsOfFile:p] : [UIImage imageNamed:n];
}

- (NSMenu *)_buildMenu {
    NSMenu *m = [[NSMenu alloc] initWithTitle:@"Battery"];
    NSMenuItem *pct = [[NSMenuItem alloc] initWithTitle:@"100%" action:nil target:nil];
    [m addItem:pct];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Show Percentage" action:nil target:nil];
    [m addItemWithTitle:@"Open Energy Saver…" action:nil target:nil];
    return m;
}

- (void)dealloc { [_timer invalidate]; }

@end
