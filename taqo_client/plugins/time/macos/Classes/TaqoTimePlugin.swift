import Cocoa
import FlutterMacOS
import os

private let CALLBACK_HANDLE = "callback"
private let BG_CALLBACK_HANDLE = "background_callback"

private func _log(_ args: CVarArg...) {
  if #available(macOS 10.12, *) {
    os_log("TaqoTimePlugin: %s", args)
  }
}

public class TaqoTimePlugin: NSObject, FlutterPlugin {
  private static let channelName = "taqo_time_plugin"
  private static let initialize = "initialize"
  private static let cancel = "cancel"

  private static let bgCallbackMethod = "backgroundIsolateCallback"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
    let instance = TaqoTimePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  @objc private func timeChanged(notification: NSNotification) {
    _log("timeChanged")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case TaqoTimePlugin.initialize:
        NotificationCenter.default.addObserver(self, selector: #selector(self.timeChanged), name: NSNotification.Name.NSSystemClockDidChange, object: nil)

        result(true)
      case TaqoTimePlugin.cancel:
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSSystemClockDidChange, object: nil)

        result(true)
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
