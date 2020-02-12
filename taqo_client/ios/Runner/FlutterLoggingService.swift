import Foundation

let window = (UIApplication.shared.delegate as! FlutterAppDelegate).window
let flutterView =
window?.rootViewController as! FlutterViewController;
let channel = FlutterMethodChannel(name: "com.taqo.survey.taqosurvey/logging", binaryMessenger: flutterView.binaryMessenger)

func flutter_log(_ level: String, _ message: String) {
  channel.invokeMethod("log", arguments: ["level":level,"message":message])
}
