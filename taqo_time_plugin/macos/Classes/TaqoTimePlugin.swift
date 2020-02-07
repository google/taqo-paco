import Cocoa
import FlutterMacOS

public class TaqoTimePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "taqo_time_plugin", binaryMessenger: registrar.messenger)
    let instance = TaqoTimePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case initialize:
        result(true)
      case cancel:
        result(true)
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
