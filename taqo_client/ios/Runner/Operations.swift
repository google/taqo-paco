import Foundation

class DartMethodOperation: Operation {
  let channelName: String
  let methodName: String

  var _isExecuting: Bool = false
  var _isFinished: Bool = false

  init(channelName: String, methodName:String) {
    self.channelName = channelName
    self.methodName = methodName
  }

  override var isAsynchronous: Bool {
    return true
  }

  override var isExecuting: Bool {
    return _isExecuting
  }

  override var isFinished: Bool {
    return _isFinished
  }

  func finish() {
    guard _isExecuting else {return}

    willChangeValue(forKey: #keyPath(isExecuting))
    willChangeValue(forKey: #keyPath(isFinished))

    _isExecuting = false
    _isFinished = true

    didChangeValue(forKey: #keyPath(isFinished))
    didChangeValue(forKey: #keyPath(isExecuting))
    return ()
  }

  override func start() {
    willChangeValue(forKey: #keyPath(isExecuting))
    _isExecuting = true
    didChangeValue(forKey: #keyPath(isExecuting))

    guard  !isCancelled else {
      self.finish()
      return
    }

    DispatchQueue.main.async {
      let window = (UIApplication.shared.delegate as! FlutterAppDelegate).window
      let flutterView = window?.rootViewController as! FlutterViewController;
      let channel = FlutterMethodChannel(name: self.channelName, binaryMessenger: flutterView.binaryMessenger)

      channel.invokeMethod(self.methodName, arguments: nil)
      {
        (resultDart: Any?) -> Void in
        if let error = resultDart as? FlutterError {
          flutter_log("WARNING", "Calling channel method \(self.channelName)/\(self.methodName) has error: FlutterError(\(error.code), \(String(describing: error.message)), \(String(describing: error.details)))")
          self.cancel()
        } else if FlutterMethodNotImplemented.isEqual(resultDart) {
          flutter_log("WARNING", "Calling channel method \(self.channelName)/\(self.methodName) returns FlutterMethodNotImplemented error")
          self.cancel()
        }
        self.finish()
      }
    }
  }
}
