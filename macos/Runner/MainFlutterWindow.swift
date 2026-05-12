import Cocoa
import FlutterMacOS

/// Resolved theme snapshot the native chrome renders. Sourced from
/// `UserDefaults` (mirror written by Flutter) when available, falling back to
/// the v2 light-Sand / dark-Espresso defaults derived from `NSAppearance`.
struct NinjaWindowTheme {
  let background: NSColor
  let titleColor: NSColor
  let isDark: Bool

  static func fromDefaults() -> NinjaWindowTheme? {
    let d = UserDefaults.standard
    guard
      let bgHex = d.string(forKey: "ninja.window.bgHex"),
      let titleHex = d.string(forKey: "ninja.window.titleHex"),
      let brightness = d.string(forKey: "ninja.window.brightness"),
      let bg = NSColor(ninjaHex: bgHex),
      let title = NSColor(ninjaHex: titleHex)
    else { return nil }
    return NinjaWindowTheme(
      background: bg, titleColor: title, isDark: brightness == "dark")
  }

  // Byte-identical to the values previously hardcoded in awakeFromNib +
  // presentSplash, so first-ever-launch behavior is unchanged.
  static func fromSystemAppearance(_ appearance: NSAppearance) -> NinjaWindowTheme {
    let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    if isDark {
      return NinjaWindowTheme(
        background: NSColor(red: 0x15/255.0, green: 0x14/255.0,
                            blue: 0x0F/255.0, alpha: 1.0),
        titleColor: NSColor(red: 0xF6/255.0, green: 0xF4/255.0,
                            blue: 0xEF/255.0, alpha: 1.0),
        isDark: true)
    }
    return NinjaWindowTheme(
      background: NSColor(red: 0xF6/255.0, green: 0xF4/255.0,
                          blue: 0xEF/255.0, alpha: 1.0),
      titleColor: NSColor(red: 0x1A/255.0, green: 0x18/255.0,
                          blue: 0x14/255.0, alpha: 1.0),
      isDark: false)
  }

  static func resolve(_ appearance: NSAppearance) -> NinjaWindowTheme {
    return fromDefaults() ?? fromSystemAppearance(appearance)
  }
}

extension NSColor {
  /// 6-char hex (e.g. "F6F4EF") → NSColor. Nil on any malformed input so
  /// callers can fall back gracefully rather than crash on a corrupted pref.
  convenience init?(ninjaHex: String) {
    guard ninjaHex.count == 6, let v = UInt32(ninjaHex, radix: 16) else {
      return nil
    }
    self.init(
      red:   CGFloat((v >> 16) & 0xFF) / 255.0,
      green: CGFloat((v >>  8) & 0xFF) / 255.0,
      blue:  CGFloat( v        & 0xFF) / 255.0,
      alpha: 1.0)
  }
}

class MainFlutterWindow: NSWindow {
  private var titleLabel: NSTextField?
  private var themeChannel: FlutterMethodChannel?
  // Until Flutter pushes its first `apply`, we honor live OS-appearance
  // changes natively so `ThemeMode.system` users who flip Dark Mode during
  // the Dart-init window see the right titlebar. Once Flutter takes over,
  // it republishes on its own via MediaQuery and the KVO path stays silent.
  private var flutterHasPushed = false

  override func awakeFromNib() {
    let initial = NinjaWindowTheme.resolve(self.effectiveAppearance)

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    apply(initial)

    RegisterGeneratedPlugins(registry: flutterViewController)

    installCenteredTitle(initial: initial)

    let channel = FlutterMethodChannel(
      name: "invoice_ninja/native_window_theme",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      guard call.method == "apply" else {
        result(FlutterMethodNotImplemented); return
      }
      guard
        let args = call.arguments as? [String: Any],
        let bgHex = args["bgHex"] as? String,
        let titleHex = args["titleHex"] as? String,
        let brightness = args["brightness"] as? String,
        let bg = NSColor(ninjaHex: bgHex),
        let title = NSColor(ninjaHex: titleHex)
      else {
        result(FlutterError(
          code: "bad_args",
          message: "expected bgHex/titleHex/brightness strings",
          details: nil))
        return
      }
      self.flutterHasPushed = true
      self.apply(NinjaWindowTheme(
        background: bg, titleColor: title, isDark: brightness == "dark"))
      let d = UserDefaults.standard
      d.set(bgHex, forKey: "ninja.window.bgHex")
      d.set(titleHex, forKey: "ninja.window.titleHex")
      d.set(brightness, forKey: "ninja.window.brightness")
      result(nil)
    }
    self.themeChannel = channel

    NSApp.addObserver(self,
                      forKeyPath: "effectiveAppearance",
                      options: [.new],
                      context: nil)

    super.awakeFromNib()
  }

  override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey: Any]?,
                             context: UnsafeMutableRawPointer?) {
    if keyPath == "effectiveAppearance", !flutterHasPushed {
      apply(NinjaWindowTheme.fromSystemAppearance(NSApp.effectiveAppearance))
    }
  }

  deinit {
    NSApp.removeObserver(self, forKeyPath: "effectiveAppearance")
  }

  private func apply(_ theme: NinjaWindowTheme) {
    self.backgroundColor = theme.background
    (self.contentViewController as? FlutterViewController)?.backgroundColor =
      theme.background
    // Drives traffic-light glyph color and any native sheets/menus the window
    // presents; keeps things legible when the user picks a cross-brightness
    // variant (e.g. Espresso while macOS is in Light Mode).
    self.appearance = NSAppearance(named: theme.isDark ? .darkAqua : .aqua)
    titleLabel?.textColor = theme.titleColor
  }

  // macOS defaults the titlebar text to be left-aligned (or centered between
  // the traffic lights and the window's right edge, depending on the OS
  // version). Replace it with a custom NSTextField pinned to the titlebar's
  // horizontal center so the app name reads as truly centered.
  private func installCenteredTitle(initial theme: NinjaWindowTheme) {
    self.titleVisibility = .hidden

    guard let titlebarView = self.standardWindowButton(.closeButton)?.superview
    else { return }

    let label = NSTextField(labelWithString: self.title)
    label.font = NSFont.titleBarFont(ofSize: NSFont.systemFontSize(for: .regular))
    label.textColor = theme.titleColor
    label.alignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    titlebarView.addSubview(label)

    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: titlebarView.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: titlebarView.centerYAnchor),
    ])
    self.titleLabel = label
  }
}
