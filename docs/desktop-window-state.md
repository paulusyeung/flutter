# Desktop window state

Each desktop runner persists window size, position, and fullscreen across launches via the host OS's native preference store. No Dart or Flutter package involvement — the goal is one short native function per platform, idiomatic to that platform's APIs. **N/A on web** — the browser owns the window chrome; there is nothing to persist.

**Contract** — every desktop runner does the same three things:
1. Read saved state at window-construction time, before the window is shown.
2. Write on every geometry change (move / resize) and on every fullscreen transition completion.
3. Fall back to the platform-native default frame on first launch (the values declared in the platform's window template — XIB on macOS, manifest / template on Windows, default size call on Linux).

**macOS** — `macos/Runner/MainFlutterWindow.swift` → `setUpWindowStatePersistence()`. Frame via `NSWindow.setFrameAutosaveName` (NSUserDefaults key `NSWindow Frame InvoiceNinjaMainWindow`, derived by AppKit); fullscreen bool via `NSWindowDelegate.windowDidEnter/ExitFullScreen` → NSUserDefaults key `ninja.window.isFullscreen`. `isRestorable = false` to keep AppKit's autosave as the only mechanism (otherwise Cocoa state restoration would override it after `awakeFromNib`).

**Windows** *(when added)* — `windows/runner/flutter_window.cpp` → `SetUpWindowStatePersistence()`. Use `WINDOWPLACEMENT` (covers normal-rect + maximized / minimized state in one struct) read & written under `HKCU\Software\InvoiceNinja\Window`. Persist on `WM_MOVE` / `WM_SIZE` / `WM_DESTROY`; restore in `OnCreate` via `SetWindowPlacement`. For fullscreen (Windows has no built-in fullscreen — it's a borderless window covering the monitor), persist a separate `Fullscreen` DWORD.

**Linux** *(when added)* — `linux/runner/my_application.cc` → `setup_window_state_persistence()`. Connect `configure-event` (geometry) and `window-state-event` (fullscreen / maximize); persist to `~/.config/invoice_ninja/window-state.ini` via `GKeyFile`. Restore in `activate` via `gtk_window_set_default_size` + `gtk_window_move` + `gtk_window_fullscreen` as appropriate.

## Desktop hidden title bar

Every desktop platform hides the OS title bar and integrates the window controls into the app chrome. The goal is the same everywhere; the **implementation diverges** because macOS keeps its real controls while Windows/Linux do not (see the divergence note below). macOS is wired today; Windows/Linux follow this contract when their runners are added.

**Shared Flutter layer** (platform-agnostic):
- `Env.isDesktop` (`lib/app/env.dart`) — the single "is this desktop" gate.
- `NativeWindow` (`lib/app/native_window.dart`) — bridge over the `invoice_ninja/native_window` method channel, mirroring the `native_window_theme` bridge; no-op off desktop. Method set: `startDrag`, `doubleClick`, `minimize`, `toggleMaximize`, `close`, `setContentSize`, `setWindowButtonsHidden`.
- `WindowCaptionStrip` (`lib/ui/features/shell/widgets/window_caption_strip.dart`) — the draggable caption strip at the top of the sidebar (and narrow-layout column).
- `WindowControls` *(future, Win/Linux)* — a drawn min/max/close cluster placed **top-right** over the content top (OS convention). Not needed on macOS.

**Channel method set** — `startDrag` (begin a native move-drag), `doubleClick` (title-bar double-click action), `minimize`, `toggleMaximize`, `close`, plus the Debug Panel screenshot tools: `setContentSize` (resize the content area to `{width, height}` logical points preserving the visual top-left, exiting fullscreen first if needed; returns the achieved `{width, height}` so Dart can detect clamping — AppKit constrains the frame to the visible display, so a screenshot size larger than the screen clamps and surfaces via the returned size, which the Debug Panel warns on) and `setWindowButtonsHidden` (`{hidden}` — toggle the native window buttons; **deliberately never persisted**, so every launch starts with visible buttons). macOS implements `startDrag` + `doubleClick` + the two screenshot methods (its native buttons cover the rest); Windows/Linux implement all of them when added.

**macOS** *(done)* — the "full-size content" look: no title-bar strip, the FlutterView fills the window, and the **real** traffic-light buttons float over its top-left (the top of the sidebar). `MainFlutterWindow.swift` → `configureHiddenTitleBar()` sets `titleVisibility = .hidden`, `titlebarAppearsTransparent`, `titlebarSeparatorStyle = .none` (macOS 11+), `styleMask.insert(.fullSizeContentView)`. The window stays `.titled` so the system buttons exist and keep their automatic active/inactive graying; `self.title` is retained for Mission Control / the Window menu. `WindowCaptionStrip` reserves 28 px and calls `startDrag` → `NSWindow.performDrag(with:)` and `doubleClick` → the user's configured action. Traffic-light glyph + inactive-gray color follow the themed `NSAppearance` set in `apply(_:)`. No drawn controls — `minimize`/`toggleMaximize`/`close` are unused here.

**Windows** *(when added)* — `flutter create --platforms=windows .`. Make the window frameless via the custom-frame technique in `windows/runner/win32_window.cpp`: handle `WM_NCCALCSIZE` to drop the caption while keeping the sizing border so **resize + Aero Snap survive**, and `WM_NCHITTEST` for the resize edges. Channel handlers: `startDrag` → `ReleaseCapture(); SendMessage(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);` · `minimize` → `ShowWindow(hwnd, SW_MINIMIZE)` · `toggleMaximize` → `ShowWindow(hwnd, IsZoomed(hwnd) ? SW_RESTORE : SW_MAXIMIZE)` · `close` → `PostMessage(hwnd, WM_CLOSE, 0, 0)` · `doubleClick` → toggle maximize. Flutter draws min/max/close top-right (`WindowControls`). Window-state persistence per the Windows section above (`SetUpWindowStatePersistence`, `WINDOWPLACEMENT`, `HKCU\Software\InvoiceNinja\Window`).

**Linux** *(when added)* — `flutter create --platforms=linux .`. The Flutter template installs a `GtkHeaderBar`; remove it and call `gtk_window_set_decorated(window, FALSE)` in `linux/runner/my_application.cc`. Channel handlers: `startDrag` → `gtk_window_begin_move_drag(...)` · resize → `gtk_window_begin_resize_drag(...)` · `minimize` → `gtk_window_iconify` · `toggleMaximize` → `gtk_window_maximize` / `gtk_window_unmaximize` · `close` → `gtk_window_close` · `doubleClick` → toggle maximize. Flutter draws min/max/close top-right (`WindowControls`). Window-state persistence per the Linux section above (`setup_window_state_persistence`, `GKeyFile`).

**Divergence note** — macOS keeps the *genuine* system buttons (so active/inactive graying, accessibility, and the system menu are free); Windows/Linux become frameless, which deletes the native buttons, so the app must **draw its own** (top-right) and handle window resize itself.

**When the Win/Linux runners land** — add `windows`/`linux` to the CLAUDE.md app description; add the `WindowControls` widget and drop the `SizedBox.shrink` early-return in `WindowCaptionStrip` for those platforms; wire the native handlers above.
