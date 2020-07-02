import Cocoa
import FlutterMacOS
import ServiceManagement

private let hasBeenLaunchedBefore = "isFirstLaunch"

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Seting LoginItem -> True
    let launcherAppId = "com.taqo.survey.TaqoLauncher"
    SMLoginItemSetEnabled(launcherAppId as CFString, true)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
