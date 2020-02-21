import Foundation
import Flutter

func scheduleSyncDataBGTasks() {
  _ = scheduleBGProcessingTask(
    identifier: "com.taqo.survey.taqoSurvey.syncData.processing",
    requiresExternalPower: false,
    requiresNetworkConnectivity: true
  )
  _ = scheduleBGAppRefreshTask(identifier: "com.taqo.survey.taqoSurvey.syncData.refresh")
}

func handleNotifySyncService(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) -> Void {
  let queue = OperationQueue()
  queue.maxConcurrentOperationCount = 1

  let syncDataOperation = DartMethodOperation(channelName: "com.taqo.survey.taqosurvey/sync-service", methodName: "runSyncService")

  var bgTaskIdentifier : UIBackgroundTaskIdentifier!
  bgTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
    flutter_log("WARNING", "UIApplication background task for syncData got cancelled.")
    syncDataOperation.cancel()
  })

  syncDataOperation.completionBlock = {
    let success = !syncDataOperation.isCancelled
    flutter_log("INFO", "UIApplication background task for syncData is completed with status: \(success)")
    if !success {
      scheduleSyncDataBGTasks()
    }
    UIApplication.shared.endBackgroundTask(bgTaskIdentifier)
  }
  
  queue.addOperation(syncDataOperation)
  result(nil)

}
