import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let isDark = self.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let bgColor: NSColor = isDark
      ? NSColor(red: 0x15/255.0, green: 0x14/255.0, blue: 0x0F/255.0, alpha: 1.0)
      : NSColor(red: 0xF6/255.0, green: 0xF4/255.0, blue: 0xEF/255.0, alpha: 1.0)
    self.backgroundColor = bgColor

    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = bgColor
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
