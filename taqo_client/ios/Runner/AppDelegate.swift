import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    SwiftTaqoTimePlugin.setPluginRegistrantCallback({ (registry: FlutterPluginRegistry) in
        // Copy what we need from GeneratedPlugins.m
        if (!registry.hasPlugin("FLTPathProviderPlugin")) {
          FLTPathProviderPlugin.register(with: registry.registrar(forPlugin: "FLTPathProviderPlugin"))
        }
        if (!registry.hasPlugin("FLTSharedPreferencesPlugin")) {
          FLTSharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "FLTSharedPreferencesPlugin"))
        }
        if (!registry.hasPlugin("FlutterLocalNotificationsPlugin")) {
          FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin"))
        }
        if (!registry.hasPlugin("SqflitePlugin")) {
          SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
        }
        if (!registry.hasPlugin("TaqoTimePlugin")) {
          TaqoTimePlugin.register(with: registry.registrar(forPlugin: "TaqoTimePlugin"))
        }
      })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

func pluginRegistrantCallback(_ registry: FlutterPluginRegistry) {
  if (!registry.hasPlugin("TaqoTimePlugin")) {
    TaqoTimePlugin.register(with: registry.registrar(forPlugin: "TaqoTimePlugin"))
  }
  GeneratedPluginRegistrant.register(with: registry)
}
