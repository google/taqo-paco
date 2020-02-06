import UIKit
import Flutter

import BackgroundTasks


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {

    // Register method channels
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let syncServiceChannel = FlutterMethodChannel(name: "com.taqo.survey.taqosurvey/sync-service",
                                              binaryMessenger: controller.binaryMessenger)

    syncServiceChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "notifySyncService":
        handleNotifySyncService(call, result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })


    // Register background tasks
    BGTaskScheduler.shared.register(forTaskWithIdentifier:
      "com.taqo.survey.taqoSurvey.syncData",
                                    using: nil)
    {task in
      handleBackgroundSync(task: task as! BGProcessingTask)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
