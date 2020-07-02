import Flutter
import UIKit

public class SwiftMacosLaunchDaemonPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "macos_launch_daemon", binaryMessenger: registrar.messenger())
    let instance = SwiftMacosLaunchDaemonPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
