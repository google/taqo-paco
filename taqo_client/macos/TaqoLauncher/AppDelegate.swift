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
import Darwin
import Foundation

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

    // Create a pseudo tty as the stdin of taqo_daemon, so that when taqo_daemon calls
    // alerter, alerter won't read an empty message from the stdin.
    let fd = posix_openpt(O_RDWR)
    grantpt(fd)
    unlockpt(fd)
    let pty = FileHandle.init(forUpdatingAtPath: String.init(cString: ptsname(fd)))

    let task = Process()
    task.executableURL = URL(fileURLWithPath: taqoDaemon.absoluteString)
    task.arguments = []
    task.standardInput = pty

    if let outUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("com.taqo/server.out", isDirectory: false) {
      if !FileManager.default.fileExists(atPath: outUrl.path) {
        FileManager.default.createFile(atPath: outUrl.path, contents: nil)
      }
      if let outFile = try? FileHandle.init(forWritingTo: outUrl) {
        task.standardOutput = outFile
      }
    }

    if let errUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("com.taqo/server.err", isDirectory: false) {
      if !FileManager.default.fileExists(atPath: errUrl.path) {
        FileManager.default.createFile(atPath: errUrl.path, contents: nil)
      }
      if let errFile = try? FileHandle.init(forWritingTo: errUrl) {
        task.standardError = errFile
      }
    }

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
