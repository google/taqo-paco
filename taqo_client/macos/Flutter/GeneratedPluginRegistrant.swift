//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import flutter_local_notifications
import macos_launch_daemon
import path_provider_macos
import sqflite
import taqo_email_plugin
import taqo_time_plugin
import url_launcher_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FlutterLocalNotificationsPlugin.register(with: registry.registrar(forPlugin: "FlutterLocalNotificationsPlugin"))
  MacosLaunchDaemonPlugin.register(with: registry.registrar(forPlugin: "MacosLaunchDaemonPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  TaqoEmailPlugin.register(with: registry.registrar(forPlugin: "TaqoEmailPlugin"))
  TaqoTimePlugin.register(with: registry.registrar(forPlugin: "TaqoTimePlugin"))
  UrlLauncherPlugin.register(with: registry.registrar(forPlugin: "UrlLauncherPlugin"))
}
