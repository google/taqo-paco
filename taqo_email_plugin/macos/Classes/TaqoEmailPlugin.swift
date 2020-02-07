import Cocoa
import FlutterMacOS

private let CHANNEL_NAME : String = "taqo_email_plugin"
private let SEND_EMAIL : String = "send_email"
private let TO_ARG : String = "to"
private let SUBJ_ARG : String = "subject"

public class TaqoEmailPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: registrar.messenger)
    let instance = TaqoEmailPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch(call.method) {
    case SEND_EMAIL:
      let args = call.arguments as? [String: String]
      let to = args?[TO_ARG]
      let subject = args?[SUBJ_ARG]?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      if (to != nil && subject != nil) {
        if let url = URL(string: "mailto:\(to!)?subject=\(subject!)") {
          NSWorkspace.shared.open(url)
        }
      }
      result("Success")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
