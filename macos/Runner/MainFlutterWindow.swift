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
  private var themeChannel: FlutterMethodChannel?
  private var windowControlChannel: FlutterMethodChannel?
  private var splashChannel: FlutterMethodChannel?
  private var splashView: NSView?
  private var splashLogoLayer: CALayer?
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

  // Splash animation tuning.
  private static let splashMinimumDwell: CFTimeInterval = 0.5
  private static let splashFadeInDuration: CFTimeInterval = 0.35
  private static let splashExitDuration: CFTimeInterval = 0.35
  private static let splashReducedExitDuration: CFTimeInterval = 0.20
  private static let splashEntryTransformKey = "ninja.splash.entryTransform"
  private static let splashEntryOpacityKey = "ninja.splash.entryOpacity"
  private static let splashExitScaleKey = "ninja.splash.exitScale"

  override func awakeFromNib() {
    let initial = NinjaWindowTheme.resolve(self.effectiveAppearance)

    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    configureHiddenTitleBar()

    setUpWindowStatePersistence()

    apply(initial)

    RegisterGeneratedPlugins(registry: flutterViewController)

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

    let windowControlChannel = FlutterMethodChannel(
      name: "invoice_ninja/native_window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    windowControlChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "startDrag":
        // NSApp.currentEvent during an active Flutter pan is the
        // leftMouseDragged event; performDrag hands off to AppKit's native
        // drag loop. Mirrors window_manager's startDragging.
        if let event = NSApp.currentEvent { self.performDrag(with: event) }
        result(nil)
      case "doubleClick":
        // Honor System Settings ▸ Desktop & Dock ▸ "double-click a window's
        // title bar to" — Maximize (zoom) is the default; respect Minimize/None.
        let action =
          UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick")
          ?? "Maximize"
        if action == "Minimize" {
          self.miniaturize(nil)
        } else if action != "None" {
          self.zoom(nil)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.windowControlChannel = windowControlChannel

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
  }

  // Hidden title bar ("full-size content" look): the FlutterView fills the whole
  // window and the real traffic-light buttons float over its top-left (the top
  // of the sidebar). The window stays `.titled` so those system buttons still
  // exist — keeping their automatic active/inactive graying — and `self.title`
  // is retained for Mission Control and the Window menu.
  private func configureHiddenTitleBar() {
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    // titlebarSeparatorStyle is macOS 11+; the deployment target is 10.15.
    if #available(macOS 11.0, *) {
      self.titlebarSeparatorStyle = .none
    }
    self.styleMask.insert(.fullSizeContentView)
    // Window dragging is driven explicitly from the Flutter sidebar strip via
    // `performDrag` (background dragging wouldn't work through the FlutterView).
    self.isMovableByWindowBackground = false
  }

  // Native splash: cover the FlutterViewController with a themed view and the
  // logo until Flutter signals it has rendered its first frame. Lives in the
  // main window (not a floating NSWindow) so there's no flicker between
  // splash dismissal and the first Flutter paint.
  //
  // The logo is an owned CALayer (sublayer of splash.layer, not an AppKit
  // layer-backed NSImageView) so every transform scales about its (0.5, 0.5)
  // anchor with no AppKit-driven drift. It zooms in from center (scale
  // 0.90 → 1.0, plain ease-out, no spring/overshoot) while fading in, then
  // expands from center (scale → 1.30) as it crossfades out on dismiss. All
  // animation is suppressed under `accessibilityDisplayShouldReduceMotion` —
  // reduced path is a static logo + plain 0.2 s alpha fade.
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

    let logoSize = NSSize(width: 480, height: 114)
    let logoOrigin = NSPoint(
      x: (splash.bounds.width - logoSize.width) / 2,
      y: (splash.bounds.height - logoSize.height) / 2)

    // The logo is a plain CALayer we own, parented to the (self-managed)
    // splash.layer — NOT an AppKit layer-backed NSImageView. AppKit never
    // relayouts a sublayer we add and its anchorPoint stays (0.5, 0.5), so
    // every scale animation is guaranteed to grow/shrink about the exact
    // visual center (no drift). Flexible margins keep it centered if the
    // window resizes during the (short) splash.
    let logoLayer = CALayer()
    logoLayer.frame = NSRect(origin: logoOrigin, size: logoSize)
    logoLayer.contentsGravity = .resizeAspect
    logoLayer.contentsScale = self.backingScaleFactor
    logoLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    logoLayer.autoresizingMask = [
      .layerMinXMargin, .layerMaxXMargin,
      .layerMinYMargin, .layerMaxYMargin]
    if let logo = NSImage(named: "LogoSplash"),
       let cg = logo.cgImage(
         forProposedRect: nil, context: nil, hints: nil) {
      logoLayer.contents = cg
    }
    splash.layer?.addSublayer(logoLayer)

    contentView.addSubview(splash)
    splashView = splash
    splashLogoLayer = logoLayer

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
    guard let layer = splashLogoLayer else { return }

    if reduceMotion() {
      layer.opacity = 1.0
      layer.transform = CATransform3DIdentity
      return
    }

    layer.opacity = 0
    layer.transform = CATransform3DMakeScale(0.90, 0.90, 1.0)

    // Clean centered zoom-in — plain ease-out, no spring/overshoot — matching
    // the iOS Flutter overlay exactly. Scales about the layer's (0.5, 0.5)
    // anchor, so the wordmark grows in place with no apparent movement.
    let scale = CABasicAnimation(keyPath: "transform.scale")
    scale.fromValue = 0.90
    scale.toValue = 1.0
    scale.duration = Self.splashFadeInDuration
    scale.timingFunction = CAMediaTimingFunction(name: .easeOut)

    let fade = CABasicAnimation(keyPath: "opacity")
    fade.fromValue = 0.0
    fade.toValue = 1.0
    fade.duration = Self.splashFadeInDuration
    fade.timingFunction = CAMediaTimingFunction(name: .easeOut)

    // Commit model values to the end state before adding animations — once
    // each animation removes itself the layer stays settled at identity / 1.
    layer.transform = CATransform3DIdentity
    layer.opacity = 1.0

    layer.add(scale, forKey: Self.splashEntryTransformKey)
    layer.add(fade, forKey: Self.splashEntryOpacityKey)
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

    let reduce = reduceMotion()
    let duration =
      reduce ? Self.splashReducedExitDuration : Self.splashExitDuration

    NSAnimationContext.runAnimationGroup({ ctx in
      ctx.duration = duration
      ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
      splash.animator().alphaValue = 0
      if !reduce, let layer = splashLogoLayer {
        let scaleUp = CABasicAnimation(keyPath: "transform.scale")
        scaleUp.fromValue = 1.0
        scaleUp.toValue = 1.30
        scaleUp.duration = duration
        scaleUp.timingFunction = CAMediaTimingFunction(name: .easeOut)
        scaleUp.fillMode = .forwards
        scaleUp.isRemovedOnCompletion = false
        layer.add(scaleUp, forKey: Self.splashExitScaleKey)
      }
    }, completionHandler: { [weak self] in
      splash.removeFromSuperview()
      // Leave splashChannel installed: after hot restart, Dart re-fires
      // dismiss() and finds no handler if we tear it down. The early
      // `guard let splash = splashView` above makes the second call a
      // cheap no-op; [weak self] in the handler prevents a retain cycle.
      self?.splashLogoLayer = nil
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
