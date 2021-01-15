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

import UIKit
import Flutter

import BackgroundTasks


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {

    // Register method channels
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let syncServiceChannel = FlutterMethodChannel(name: "com.taqo.survey.taqosurvey/sync-service",
                                              binaryMessenger: controller.binaryMessenger)

    syncServiceChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "notifySyncService":
        handleNotifySyncService(call, result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    // Register background tasks
    BGTaskScheduler.shared.register(forTaskWithIdentifier:
      "com.taqo.survey.taqoSurvey.syncData.processing",
                                    using: nil)
    {task in
      handleBackgroundSync(task: task)
    }

    BGTaskScheduler.shared.register(forTaskWithIdentifier:
      "com.taqo.survey.taqoSurvey.syncData.refresh",
                                    using: nil)
    {task in
      handleBackgroundSync(task: task)
    }

    GeneratedPluginRegistrant.register(with: self)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    SwiftTaqoTimePlugin.setPluginRegistrantCallback({ (registry: FlutterPluginRegistry) in
        // Copy what we need from GeneratedPlugins.m
        if (!registry.hasPlugin("FLTPathProviderPlugin")) {
          FLTPathProviderPlugin.register(with: registry.registrar(forPlugin: "FLTPathProviderPlugin")!)
        }
        if (!registry.hasPlugin("FlutterLocalNotificationsPlugin")) {
          FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin")!)
        }
        if (!registry.hasPlugin("SqflitePlugin")) {
          SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin")!)
        }
        if (!registry.hasPlugin("TaqoTimePlugin")) {
          TaqoTimePlugin.register(with: registry.registrar(forPlugin: "TaqoTimePlugin")!)
        }
      })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

func pluginRegistrantCallback(_ registry: FlutterPluginRegistry) {
  if (!registry.hasPlugin("TaqoTimePlugin")) {
    TaqoTimePlugin.register(with: registry.registrar(forPlugin: "TaqoTimePlugin")!)
  }
  GeneratedPluginRegistrant.register(with: registry)
}
