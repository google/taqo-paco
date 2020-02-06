import Foundation
import os.log

class SyncDataOperation: Operation {
  override func main() {
    DispatchQueue.main.async {
      let window = (UIApplication.shared.delegate as! FlutterAppDelegate).window
      let flutterView =
        window?.rootViewController as! FlutterViewController;
      let channel = FlutterMethodChannel(name: "com.taqo.survey.taqosurvey/sync-service", binaryMessenger: flutterView.binaryMessenger)
      let methodName = "runSyncService"

      os_log("Calling %@...", type:.info, methodName)
      channel.invokeMethod(methodName, arguments: nil)
      {
        (result: Any?) -> Void in
        if let error = result as? FlutterError {
          os_log("Calling %@ through method channel failed: %@", type: .error, methodName, error.message!)
        } else if FlutterMethodNotImplemented.isEqual(result) {
          os_log("%@ was not implemented as a channel method", type: .error, methodName)
        } else {
          os_log("Successfully called %@ through method channel", type: .info, methodName)
        }
      }
    }
  }
}
