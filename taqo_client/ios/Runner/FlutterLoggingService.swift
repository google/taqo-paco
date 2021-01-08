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

func flutter_log(_ level: String, _ message: String) {
  DispatchQueue.main.async {
    let window = (UIApplication.shared.delegate as! FlutterAppDelegate).window
    let flutterView = window?.rootViewController as! FlutterViewController;
    let channel = FlutterMethodChannel(name: "com.taqo.survey.taqosurvey/logging", binaryMessenger: flutterView.binaryMessenger)
    channel.invokeMethod("log", arguments: ["level":level,"message":message])
  }
}
