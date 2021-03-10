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

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!


  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Insert code here to initialize your application
    let bundlePath = URL(string: Bundle.main.bundlePath)
    let pathToBin = bundlePath?.appendingPathComponent("Contents/MacOS/taqo_daemon")
    guard let taqoDaemon = pathToBin else {
      NSLog("Error finding taqo_daemon")
      return
    }

    NSLog("Launching taqo_daemon at")
    NSLog(taqoDaemon.absoluteString)

    let task = Process()
    task.executableURL = URL(fileURLWithPath: taqoDaemon.absoluteString)
    task.arguments = []
    do {
      try task.run()
    } catch {
      NSLog("Error running taqo_daemon")
    }

    NSApp.terminate(nil)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
}
