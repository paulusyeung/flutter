import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var splashWindow: NSWindow?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    presentSplash()
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  private func presentSplash() {
    // Match the main window: prefer the Flutter-resolved theme persisted to
    // UserDefaults so a relaunch under Mist or Carbon doesn't flash Sand /
    // Espresso for the splash's lifetime.
    let bgColor = NinjaWindowTheme.resolve(NSApp.effectiveAppearance).background

    let screen = NSScreen.main ?? NSScreen.screens.first
    guard let screenFrame = screen?.frame else { return }

    let size = NSSize(width: 480, height: 300)
    let origin = NSPoint(
      x: screenFrame.midX - size.width / 2,
      y: screenFrame.midY - size.height / 2
    )

    let window = NSWindow(
      contentRect: NSRect(origin: origin, size: size),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    window.isOpaque = false
    window.backgroundColor = .clear
    window.hasShadow = true
    window.level = .floating
    window.isMovable = false
    window.isReleasedWhenClosed = false

    let container = NSView(frame: NSRect(origin: .zero, size: size))
    container.wantsLayer = true
    container.layer?.backgroundColor = bgColor.cgColor
    container.layer?.cornerRadius = 14
    container.layer?.masksToBounds = true

    if let logo = NSImage(named: "LogoSplash") {
      let imageView = NSImageView(image: logo)
      imageView.imageScaling = .scaleProportionallyUpOrDown
      imageView.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(imageView)
      NSLayoutConstraint.activate([
        imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
        imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        imageView.widthAnchor.constraint(equalToConstant: 280),
        imageView.heightAnchor.constraint(equalToConstant: 66),
      ])
    }

    window.contentView = container
    window.makeKeyAndOrderFront(nil)
    splashWindow = window

    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      guard let splash = self?.splashWindow else { return }
      NSAnimationContext.runAnimationGroup({ ctx in
        ctx.duration = 0.3
        splash.animator().alphaValue = 0
      }, completionHandler: { [weak self] in
        self?.splashWindow?.orderOut(nil)
        self?.splashWindow = nil
      })
    }
  }
}
