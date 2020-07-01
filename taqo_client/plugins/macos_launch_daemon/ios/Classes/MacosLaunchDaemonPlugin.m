#import "MacosLaunchDaemonPlugin.h"
#if __has_include(<macos_launch_daemon/macos_launch_daemon-Swift.h>)
#import <macos_launch_daemon/macos_launch_daemon-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "macos_launch_daemon-Swift.h"
#endif

@implementation MacosLaunchDaemonPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMacosLaunchDaemonPlugin registerWithRegistrar:registrar];
}
@end
