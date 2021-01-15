// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import BackgroundTasks

func handleBackgroundSync(task: BGTask) {
  let queue = OperationQueue()
  queue.maxConcurrentOperationCount = 1

  let syncDataOperation = DartMethodOperation(channelName: "com.taqo.survey.taqosurvey/sync-service", methodName: "runSyncService")
  task.expirationHandler = {
    // After all operations are cancelled, the completion block below is called to set the task to complete.
    flutter_log("WARNING", "SyncData background task \(task.identifier) got cancelled.")
    queue.cancelAllOperations()
  }

  syncDataOperation.completionBlock = {
    let success = !syncDataOperation.isCancelled
    flutter_log("INFO", "SyncData background task \(task.identifier) is completed with status \(success).")
    if !success {
      if task is BGProcessingTask {
        _ = scheduleBGProcessingTask(
          identifier: "com.taqo.survey.taqoSurvey.syncData.processing",
          requiresExternalPower: false,
          requiresNetworkConnectivity: true
        )
      } else {
        _ = scheduleBGAppRefreshTask(identifier: "com.taqo.survey.taqoSurvey.syncData.refresh")
      }
    }
    task.setTaskCompleted(success: success)
  }

  queue.addOperation(syncDataOperation)
}
