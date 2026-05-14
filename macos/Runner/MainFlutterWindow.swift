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
  private var splashChannel: FlutterMethodChannel?
  private var splashView: NSView?
  private var splashLogoView: NSImageView?
  private var splashStartTime: CFTimeInterval = 0
  // Until Flutter pushes its first `apply`, we honor live OS-appearance
  // changes natively so `ThemeMode.system` users who flip Dark Mode during
  // the Dart-init window see the right titlebar. Once Flutter takes over,
  // it republishes on its own via MediaQuery and the KVO path stays silent.
  private var flutterHasPushed = false

  // macOS leg of the cross-platform window-state contract (see CLAUDE.md
  // § Desktop window state). AppKit derives the NSUserDefaults frame key
  // from windowAutosaveName as "NSWindow Frame <name>".
  private static let windowAutosaveName = "InvoiceNinjaMainWindow"
  fileprivate static let fullscreenKey = "ninja.window.isFullscreen"

  // Splash animation tuning. See CLAUDE.md note + plan file
  // `what-can-you-do-staged-lake.md` for the rationale on each value.
  private static let splashMinimumDwell: CFTimeInterval = 0.5
  private static let splashFadeInDuration: CFTimeInterval = 0.35
  private static let splashBreathingDelayAfterEntry: CFTimeInterval = 0.6
  private static let splashBreathingPeriod: CFTimeInterval = 2.4
  private static let splashExitDuration: CFTimeInterval = 0.35
  private static let splashReducedExitDuration: CFTimeInterval = 0.20
  private static let splashBreathingKey = "ninja.splash.breathing"
  private static let splashEntryTransformKey = "ninja.splash.entryTransform"
  private static let splashEntryOpacityKey = "ninja.splash.entryOpacity"
  private static let splashExitScaleKey = "ninja.splash.exitScale"

  override func awakeFromNib() {
    let initial = NinjaWindowTheme.resolve(self.effectiveAppearance)

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    setUpWindowStatePersistence()

    apply(initial)

    RegisterGeneratedPlugins(registry: flutterViewController)

    installCenteredTitle(initial: initial)
    installSplash(
      initial: initial,
      messenger: flutterViewController.engine.binaryMessenger)

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

  // Native splash: cover the FlutterViewController with a themed view and the
  // logo until Flutter signals it has rendered its first frame. Lives in the
  // main window (not a floating NSWindow) so there's no flicker between
  // splash dismissal and the first Flutter paint.
  //
  // The logo spring-settles on entry (subtle, near-critical damping — no
  // overshoot), gently breathes on slow boots (engages 600 ms after entry),
  // and scale-ups + crossfades out on dismiss. All animation is suppressed
  // under `accessibilityDisplayShouldReduceMotion` — reduced path is a
  // static logo + plain 0.2 s alpha fade.
  //
  // Dismissal: Dart calls `dismiss` on the `invoice_ninja/splash` channel
  // from a post-frame callback in `_InvoiceNinjaAppState.initState`. A 6 s
  // safety timeout fires the same fade so the user never gets stuck on the
  // splash if the engine fails to push a frame (e.g. Dart crashes during
  // bootstrap). A minimum-dwell guard prevents a half-completed entry from
  // being yanked into an exit on very fast (<200 ms) boots.
  private func installSplash(
    initial theme: NinjaWindowTheme,
    messenger: FlutterBinaryMessenger
  ) {
    guard let contentView = self.contentView else { return }
    splashStartTime = CACurrentMediaTime()

    let splash = NSView(frame: contentView.bounds)
    splash.autoresizingMask = [.width, .height]
    splash.wantsLayer = true
    splash.layer?.backgroundColor = theme.background.cgColor

    var loadedImageView: NSImageView?
    if let logo = NSImage(named: "LogoSplash") {
      let logoSize = NSSize(width: 480, height: 114)
      let origin = NSPoint(
        x: (splash.bounds.width - logoSize.width) / 2,
        y: (splash.bounds.height - logoSize.height) / 2)
      let imageView = NSImageView(
        frame: NSRect(origin: origin, size: logoSize))
      // All four margins flexible → AppKit keeps the fixed-size logo centered
      // as the splash autoresizes with the window. No Auto Layout → the
      // layer's frame is set once and the spring transform won't fight a
      // later layout pass.
      imageView.autoresizingMask = [
        .minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
      imageView.image = logo
      imageView.imageScaling = .scaleProportionallyUpOrDown
      imageView.wantsLayer = true
      splash.addSubview(imageView)
      loadedImageView = imageView
    }

    contentView.addSubview(splash)
    splashView = splash
    splashLogoView = loadedImageView

    let channel = FlutterMethodChannel(
      name: "invoice_ninja/splash", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "dismiss" {
        self?.dismissSplash()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    splashChannel = channel

    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
      self?.dismissSplash()
    }

    playSplashEntry()
  }

  private func playSplashEntry() {
    guard let logo = splashLogoView, let layer = logo.layer else { return }

    if reduceMotion() {
      layer.opacity = 1.0
      layer.transform = CATransform3DIdentity
      return
    }

    layer.opacity = 0
    layer.transform = CATransform3DMakeScale(0.95, 0.95, 1.0)

    let spring = CASpringAnimation(keyPath: "transform")
    spring.damping = 22
    spring.mass = 1
    spring.stiffness = 180
    spring.initialVelocity = 0
    spring.fromValue = NSValue(
      caTransform3D: CATransform3DMakeScale(0.95, 0.95, 1.0))
    spring.toValue = NSValue(caTransform3D: CATransform3DIdentity)
    spring.duration = spring.settlingDuration

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 0.0
    fade.toValue = 1.0
    fade.duration = Self.splashFadeInDuration
    fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

    // Commit model values to the end state before adding animations — once
    // each animation removes itself the layer stays settled at identity / 1.
    layer.transform = CATransform3DIdentity
    layer.opacity = 1.0

    layer.add(spring, forKey: Self.splashEntryTransformKey)
    layer.add(fade, forKey: Self.splashEntryOpacityKey)

    let breathingDelay =
      spring.settlingDuration + Self.splashBreathingDelayAfterEntry
    DispatchQueue.main.asyncAfter(
      deadline: .now() + breathingDelay
    ) { [weak self] in
      self?.startSplashBreathingIfStillVisible()
    }
  }

  private func startSplashBreathingIfStillVisible() {
    guard splashView != nil,
          let logo = splashLogoView,
          let layer = logo.layer else { return }
    if reduceMotion() { return }

    let breath = CABasicAnimation(keyPath: "opacity")
    breath.fromValue = 1.0
    breath.toValue = 0.95
    breath.duration = Self.splashBreathingPeriod
    breath.autoreverses = true
    breath.repeatCount = .infinity
    breath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    layer.add(breath, forKey: Self.splashBreathingKey)
  }

  private func dismissSplash() {
    guard let splash = splashView else { return }

    // Minimum dwell: never interrupt a half-completed entry animation. On
    // very fast boots we hold the splash for the remaining delta so the
    // spring gets to settle before the exit fires.
    let elapsed = CACurrentMediaTime() - splashStartTime
    if elapsed < Self.splashMinimumDwell {
      let remaining = Self.splashMinimumDwell - elapsed
      DispatchQueue.main.asyncAfter(
        deadline: .now() + remaining
      ) { [weak self] in
        self?.dismissSplash()
      }
      return
    }

    splashView = nil

    // Cleanly tear down the breathing loop: remove the looping animation,
    // then write opacity=1 back to the model so the layer doesn't snap to
    // whatever sub-1.0 value the presentation layer happened to be at.
    if let logo = splashLogoView, let layer = logo.layer {
      layer.removeAnimation(forKey: Self.splashBreathingKey)
      layer.opacity = 1.0
    }

    let reduce = reduceMotion()
    let duration =
      reduce ? Self.splashReducedExitDuration : Self.splashExitDuration

    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = duration
      ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
      splash.animator().alphaValue = 0
      if !reduce, let logo = splashLogoView, let layer = logo.layer {
        let scaleUp = CABasicAnimation(keyPath: "transform.scale")
        scaleUp.fromValue = 1.0
        scaleUp.toValue = 1.04
        scaleUp.duration = duration
        scaleUp.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleUp.fillMode = .forwards
        scaleUp.isRemovedOnCompletion = false
        layer.add(scaleUp, forKey: Self.splashExitScaleKey)
      }
    }, completionHandler: { [weak self] in
      splash.removeFromSuperview()
      // Drop the channel + handler closure so the post-splash window
      // doesn't retain a handler that references self.
      self?.splashChannel?.setMethodCallHandler(nil)
      self?.splashChannel = nil
      self?.splashLogoView = nil
    })
  }

  private func reduceMotion() -> Bool {
    return NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }

  // Window state persistence (size, position, fullscreen) — restored on
  // launch and auto-saved on every geometry / fullscreen change. See
  // CLAUDE.md § Desktop window state for the cross-platform contract that
  // Windows / Linux runners should mirror when added.
  private func setUpWindowStatePersistence() {
    // Disable Cocoa state restoration on this window so AppKit's frame
    // autosave is the single mechanism — otherwise the OS would re-apply a
    // saved frame from ~/Library/Saved Application State after awakeFromNib.
    self.isRestorable = false
    self.setFrameAutosaveName(Self.windowAutosaveName)
    self.delegate = self
    if UserDefaults.standard.bool(forKey: Self.fullscreenKey) {
      DispatchQueue.main.async { [weak self] in
        guard let self = self,
              !self.styleMask.contains(.fullScreen) else { return }
        self.toggleFullScreen(nil)
      }
    }
  }
}

extension MainFlutterWindow: NSWindowDelegate {
  func windowDidEnterFullScreen(_ notification: Notification) {
    UserDefaults.standard.set(true, forKey: Self.fullscreenKey)
  }
  func windowDidExitFullScreen(_ notification: Notification) {
    UserDefaults.standard.set(false, forKey: Self.fullscreenKey)
  }
}
