import Cocoa
import FlutterMacOS

public class MacosLaunchDaemonPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.taqo.survey", binaryMessenger: registrar.messenger)
    let instance = MacosLaunchDaemonPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "startTespServer":
      launchTaqoDaemon()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func launchTaqoDaemon() {
    let taqoUrl = URL(string: "taqo://")
    guard let url = taqoUrl else {
      NSLog("Failed to get URL for Taqo")
      return
    }

    if #available(OSX 10.15, *) {
      let conf = NSWorkspace.OpenConfiguration()
      NSWorkspace.shared.openApplication(at: url, configuration: conf, completionHandler: { (app: NSRunningApplication?, err: Error?) -> Void in
        if let _ = app {
          NSLog("TaqoLauncher started")
        } else if let _ = err {
          NSLog("Failed to open TaqoLauncher")
        }
      })
    }
  }
}
