// SPDX-License-Identifier: MIT
// MBLog — runtime diagnostic logger. Writes to /var/jb/var/mobile/MacBar.log
// (rootless jailbreak, SpringBoard runs as mobile so the dir is writable).
// One line per event, timestamped, so the user can `cat` it on device and
// paste it back to pinpoint which stage of injection failed.
#import <Foundation/Foundation.h>

static inline NSString *MBLogTimestamp(void) {
    static NSDateFormatter *fmt;
    static dispatch_once_t t;
    dispatch_once(&t, ^{ fmt = [NSDateFormatter new]; fmt.dateFormat = @"HH:mm:ss.SSS"; });
    return [fmt stringFromDate:[NSDate date]] ?: @"";
}

static inline void MBLog(NSString *fmt, ...) {
    va_list args; va_start(args, fmt);
    NSString *body = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    NSString *line = [NSString stringWithFormat:@"[%@] %@\n", MBLogTimestamp(), body ?: @"(nil)"];
    // stderr (goes to the system log / os_log when available) + file.
    fprintf(stderr, "%s", line.UTF8String);
    @try {
        static NSString *logPath;
        static dispatch_once_t p;
        dispatch_once(&p, ^{ logPath = @"/var/jb/var/mobile/MacBar.log"; });
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:logPath];
        if (!fh) {
            [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
            fh = [NSFileHandle fileHandleForWritingAtPath:logPath];
        }
        if (fh) {
            [fh seekToEndOfFile];
            [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
        }
    } @catch (NSException *e) { /* logging must never crash the host */ }
}
