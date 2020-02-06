import Foundation
import Flutter

func handleNotifySyncService(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) -> Void {
  let taskId = "com.taqo.survey.taqoSurvey.syncData"
  let success = scheduleBGProcessingTask(
    identifier: taskId ,
    requiresExternalPower: false,
    requiresNetworkConnectivity: true
  )
  if success {
    result(nil)
  } else {
    result(FlutterError(code: "BGTaskScheduleFail", message: "Failed to schedule the background task \(taskId)", details: nil))
  }

}

