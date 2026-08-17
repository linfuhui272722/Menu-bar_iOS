// SPDX-License-Identifier: MIT
#import "AppleClockExtra.h"
#import "MBTheme.h"
#import <QuartzCore/QuartzCore.h>

@interface AppleClockExtra ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation AppleClockExtra

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 140, MBMenuBarHeight())])) {
        _label = [[UILabel alloc] initWithFrame:self.menuExtraView.bounds];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _label.textAlignment = NSTextAlignmentCenter;
        _label.font = [UIFont systemFontOfSize:13];
        _label.textColor = [MBTheme menuBarTextColor];
        _label.backgroundColor = UIColor.clearColor;
        [self.menuExtraView addSubview:_label];
        [self _tick];
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                selector:@selector(_tick) userInfo:nil repeats:YES];
        self.menu = [self _buildMenu];
    }
    return self;
}

- (void)_tick {
    NSDateFormatter *f = [NSDateFormatter new];
    f.locale = [NSLocale currentLocale];
    f.timeStyle = NSDateFormatterShortStyle;
    _label.text = [f stringFromDate:[NSDate date]];
}

- (NSMenu *)_buildMenu {
    NSMenu *m = [[NSMenu alloc] initWithTitle:@"Clock"];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateStyle = NSDateFormatterFullStyle;
    df.timeStyle = NSDateFormatterShortStyle;
    [m addItemWithTitle:[df stringFromDate:[NSDate date]] action:nil target:nil];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Date & Time Preferences…" action:nil target:nil];
    return m;
}

- (void)dealloc { [_timer invalidate]; }

@end
