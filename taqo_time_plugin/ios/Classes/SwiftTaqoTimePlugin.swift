import Flutter
import UIKit
import os

private let CALLBACK_HANDLE = "callback"
private let BG_CALLBACK_HANDLE = "background_callback"

private func _log(_ args: CVarArg...) {
  if #available(iOS 10.0, *) {
    os_log("TaqoTimePlugin: %s", args)
  }
}

private class FlutterBackgroundExecutor: NSObject {
  private static let backgroundName = "com.taqo.survey/taqo_time_plugin_background"
  private static let initialized = "initialized"
  private static let bgCallbackMethod = "backgroundIsolateCallback"

  private var isCallbackDispatcherReady: Bool = false
  private var backgroundFlutterEngine: FlutterEngine? = nil
  private var backgroundChannel: FlutterMethodChannel? = nil
  var pluginRegistrantCallback: FlutterPluginRegistrantCallback? = nil

  private func isNotRunning() -> Bool {
    return !isCallbackDispatcherReady
  }

  private func initializeMethodChannel(_ isolate: FlutterBinaryMessenger) {
    backgroundChannel = FlutterMethodChannel(name: FlutterBackgroundExecutor.backgroundName, binaryMessenger: isolate, codec: FlutterJSONMethodCodec.sharedInstance())
    backgroundChannel?.setMethodCallHandler({ (_ call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case FlutterBackgroundExecutor.initialized:
        self.isCallbackDispatcherReady = true
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    })
  }

  public func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
    pluginRegistrantCallback = callback
  }

  public func startBackgroundIsolate() {
    if (isNotRunning()) {
      let userDefaults = UserDefaults()
      let callbackHandle = userDefaults.object(forKey: BG_CALLBACK_HANDLE) as? Int64
      startBackgroundIsolate(callbackHandle!)
    }
  }

  public func startBackgroundIsolate(_ callbackHandle: Int64) {
    if (backgroundFlutterEngine != nil) {
      _log("Background Isolate already started")
      return
    }

    _log("Starting background Isolate")

    if (isNotRunning()) {
      backgroundFlutterEngine = FlutterEngine(name: "TODO", project: nil, allowHeadlessExecution: true)
      let flutterCallback = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
      let entryPoint = flutterCallback?.callbackName
      let uri = flutterCallback?.callbackLibraryPath

      backgroundFlutterEngine?.run(withEntrypoint: entryPoint, libraryURI: uri)
      initializeMethodChannel(backgroundFlutterEngine!.binaryMessenger)
      pluginRegistrantCallback?(backgroundFlutterEngine!)
    }
  }

  public func executeDartCallbackInBackgroundIsolate() {
    let userDefaults = UserDefaults()
    let callbackHandle = userDefaults.object(forKey: CALLBACK_HANDLE) as? Int64
    backgroundChannel?.invokeMethod(FlutterBackgroundExecutor.bgCallbackMethod, arguments: [callbackHandle])
  }
}

public class SwiftTaqoTimePlugin: NSObject, FlutterPlugin {
  private static let channelName = "taqo_time_plugin"
  private static let initialize = "initialize"
  private static let cancel = "cancel"

  private static let bgCallbackMethod = "backgroundIsolateCallback"

  private var flutterBackgroundExecutor: FlutterBackgroundExecutor? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = SwiftTaqoTimePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  @objc private func timeChanged(notification: NSNotification) {
    flutterBackgroundExecutor?.executeDartCallbackInBackgroundIsolate()
  }

  private func setCallbackDispatcher(_ bgCallbackHandle: Int64, _ callbackHandle: Int64) {
    let userDefaults = UserDefaults()
    userDefaults.set(bgCallbackHandle, forKey: BG_CALLBACK_HANDLE)
    userDefaults.set(callbackHandle, forKey: CALLBACK_HANDLE)
  }

  private func startBackgroundIsolate(_ callbackHandle: Int64) {
    if (flutterBackgroundExecutor != nil) {
      _log("Background Isolate already started")
      return
    }
    flutterBackgroundExecutor = FlutterBackgroundExecutor()
    flutterBackgroundExecutor?.startBackgroundIsolate(callbackHandle)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case SwiftTaqoTimePlugin.initialize:
        NotificationCenter.default.addObserver(self, selector: #selector(self.timeChanged), name: NSNotification.Name.NSSystemClockDidChange, object: nil)

        let args = call.arguments as? [Int64]
        let bgCallbackHandle = args?[0]
        let callbackHandle = args?[1]

        setCallbackDispatcher(bgCallbackHandle!, callbackHandle!);
        startBackgroundIsolate(bgCallbackHandle!)

        result(true)
      case SwiftTaqoTimePlugin.cancel:
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSSystemClockDidChange, object: nil)

        result(true)
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
