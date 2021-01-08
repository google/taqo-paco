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

import Flutter
import UIKit

private let CHANNEL_NAME : String = "taqo_email_plugin"
private let SEND_EMAIL : String = "send_email"
private let TO_ARG : String = "to"
private let SUBJ_ARG : String = "subject"

public class SwiftTaqoEmailPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: CHANNEL_NAME, binaryMessenger: registrar.messenger())
    let instance = SwiftTaqoEmailPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch(call.method) {
    case SEND_EMAIL:
      let args = call.arguments as? [String: String]
      let to = args?[TO_ARG]
      let subject = args?[SUBJ_ARG]?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      if (to != nil && subject != nil) {
        if let url = URL(string: "mailto:\(to!)?subject=\(subject!)") {
          UIApplication.shared.openURL(url)
        }
      }
      result("Success")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
