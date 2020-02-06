import Foundation
import BackgroundTasks

func handleBackgroundSync(task: BGProcessingTask) {
  let queue = OperationQueue()
  queue.maxConcurrentOperationCount = 1

  let syncDataOperation = SyncDataOperation()
  task.expirationHandler = {
      // After all operations are cancelled, the completion block below is called to set the task to complete.
      queue.cancelAllOperations()
  }

  syncDataOperation.completionBlock = {
      let success = !syncDataOperation.isCancelled
      task.setTaskCompleted(success: success)
  }

  queue.addOperation(syncDataOperation)
}
