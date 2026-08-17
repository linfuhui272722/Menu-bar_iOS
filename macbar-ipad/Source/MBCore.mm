// SPDX-License-Identifier: MIT
#import "MBCore.h"
#import <objc/runtime.h>

// AppKit parity sentinel: NSVariableStatusItemLength == -1 (auto-sizing).
const CGFloat NSVariableStatusItemLength = -1.0f;

// Runtime helper: look up a private class, nil-safe (SpringBoard classes).
Class MBClassNamed(NSString *name) {
    if (name.length == 0) return Nil;
    return objc_getClass(name.UTF8String);
}
