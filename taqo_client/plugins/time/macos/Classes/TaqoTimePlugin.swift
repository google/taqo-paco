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

import Cocoa
import FlutterMacOS
import os

private let CALLBACK_HANDLE = "callback"
private let BG_CALLBACK_HANDLE = "background_callback"

public class TaqoTimePlugin: NSObject, FlutterPlugin {
  private static let channelName = "taqo_time_plugin"
  private static let initialize = "initialize"
  private static let cancel = "cancel"

  private static let bgCallbackMethod = "backgroundIsolateCallback"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger)
    let instance = TaqoTimePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  @objc private func timeChanged(notification: NSNotification) {
    if #available(macOS 10.12, *) {
      os_log("TaqoTimePlugin: timeChanged")
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case TaqoTimePlugin.initialize:
        NotificationCenter.default.addObserver(self, selector: #selector(self.timeChanged), name: NSNotification.Name.NSSystemClockDidChange, object: nil)

        result(true)
      case TaqoTimePlugin.cancel:
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSSystemClockDidChange, object: nil)

        result(true)
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
