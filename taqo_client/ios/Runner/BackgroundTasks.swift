import Foundation
import BackgroundTasks
import os.log

func scheduleBGProcessingTask(identifier: String, requiresExternalPower: Bool, requiresNetworkConnectivity: Bool) -> Bool {
  let request = BGProcessingTaskRequest(identifier: identifier)
  request.requiresExternalPower = requiresExternalPower
  request.requiresNetworkConnectivity = requiresNetworkConnectivity
  do {
    try BGTaskScheduler.shared.submit(request)
    return true
  } catch {
    os_log("Unable to schedule task %@: %@", "\(identifier)", "\(error)")
    return false
  }
}

func cancelBGTask(identifier: String) {
  BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier);
}
