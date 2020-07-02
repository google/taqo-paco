//
//  AppDelegate.swift
//  TaqoLauncher
//
//  Created by Michael Maksymowych on 6/30/20.
//  Copyright © 2020 The Flutter Authors. All rights reserved.
//

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
