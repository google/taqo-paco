import Foundation
import BackgroundTasks

func submitBGTaskRequest(_ request: BGTaskRequest) -> Bool {
  do {
    try BGTaskScheduler.shared.submit(request)
    flutter_log("INFO","Successfully scheduled task \(request.identifier)")
    return true
  } catch {
    flutter_log("WARNING","Unable to schedule task \(request.identifier): \(error)")
    return false
  }
}

func scheduleBGProcessingTask(identifier: String, requiresExternalPower: Bool, requiresNetworkConnectivity: Bool) -> Bool {
  let request = BGProcessingTaskRequest(identifier: identifier)
  request.requiresExternalPower = requiresExternalPower
  request.requiresNetworkConnectivity = requiresNetworkConnectivity
  return submitBGTaskRequest(request)
}

func scheduleBGAppRefreshTask(identifier: String) -> Bool {
  let request = BGAppRefreshTaskRequest(identifier: identifier)
  return submitBGTaskRequest(request)
}

func cancelBGTask(identifier: String) {
  BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier);
}
