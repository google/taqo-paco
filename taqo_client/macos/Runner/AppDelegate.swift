import Cocoa
import FlutterMacOS
import ServiceManagement

@NSApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Seting LoginItem -> True
    let launcherAppId = "com.taqo.survey.TaqoLauncher"
    SMLoginItemSetEnabled(launcherAppId as CFString, true)

    let taqoUrl = URL(string: "taqo://")
    guard let url = taqoUrl else {
      NSLog("Failed to get URL for Taqo")
      return
    }

    if #available(OSX 10.15, *) {
      let conf = NSWorkspace.OpenConfiguration()
      NSWorkspace.shared.openApplication(at: url, configuration: conf, completionHandler: { (app: NSRunningApplication?, err: Error?) -> Void in
        NSLog("Something happened")
        if let _ = app {
          NSLog("OK")
        } else if let _ = err {
          NSLog("ERR")
        }
      })
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
}
