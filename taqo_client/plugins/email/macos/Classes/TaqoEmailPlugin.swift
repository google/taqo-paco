import Cocoa
import FlutterMacOS
import os

private let channelName : String = "taqo_email_plugin"
private let sendEmailMethod : String = "send_email"
private let toArg : String = "to"
private let subjArg : String = "subject"

private let gmailTemplate = "https://mail.google.com/mail/?view=cm&fs=1&to=%@&su=%@"

private func log(_ msg: String, _ args: CVarArg...) {
  if #available(macOS 10.12, *) {
    os_log("TaqoEmailPlugin %s", msg, args)
  }
}

public class TaqoEmailPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
    let instance = TaqoEmailPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch(call.method) {
    case sendEmailMethod:
      guard let args = call.arguments as? [String: String] else {
        result("Failed")
        return
      }
      guard let to = args[toArg], let subj = args[subjArg] else {
        log("'to' and 'subject' args must be provided")
        result("Failed")
        return
      }
      if let subjEncode = subj.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
        if let url = URL(string: String(format: gmailTemplate, to, subjEncode)) {
          NSWorkspace.shared.open(url)
        }
      }
      result("Success")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
