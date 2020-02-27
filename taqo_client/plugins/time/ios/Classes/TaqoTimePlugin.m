#import "TaqoTimePlugin.h"
#if __has_include(<taqo_time_plugin/taqo_time_plugin-Swift.h>)
#import <taqo_time_plugin/taqo_time_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "taqo_time_plugin-Swift.h"
#endif

@implementation TaqoTimePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTaqoTimePlugin registerWithRegistrar:registrar];
}
@end
