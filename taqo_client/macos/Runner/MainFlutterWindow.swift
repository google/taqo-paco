import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    if #available(OSX 10.14, *) {
      RegisterGeneratedPlugins(registry: flutterViewController)
    }

    super.awakeFromNib()
  }
}
