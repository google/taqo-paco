#import "TaqoEmailPlugin.h"
#if __has_include(<taqo_email_plugin/taqo_email_plugin-Swift.h>)
#import <taqo_email_plugin/taqo_email_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "taqo_email_plugin-Swift.h"
#endif

@implementation TaqoEmailPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftTaqoEmailPlugin registerWithRegistrar:registrar];
}
@end
