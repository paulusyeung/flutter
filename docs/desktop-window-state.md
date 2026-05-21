# Desktop window state

Each desktop runner persists window size, position, and fullscreen across launches via the host OS's native preference store. No Dart or Flutter package involvement — the goal is one short native function per platform, idiomatic to that platform's APIs. **N/A on web** — the browser owns the window chrome; there is nothing to persist.

**Contract** — every desktop runner does the same three things:
1. Read saved state at window-construction time, before the window is shown.
2. Write on every geometry change (move / resize) and on every fullscreen transition completion.
3. Fall back to the platform-native default frame on first launch (the values declared in the platform's window template — XIB on macOS, manifest / template on Windows, default size call on Linux).

**macOS** — `macos/Runner/MainFlutterWindow.swift` → `setUpWindowStatePersistence()`. Frame via `NSWindow.setFrameAutosaveName` (NSUserDefaults key `NSWindow Frame InvoiceNinjaMainWindow`, derived by AppKit); fullscreen bool via `NSWindowDelegate.windowDidEnter/ExitFullScreen` → NSUserDefaults key `ninja.window.isFullscreen`. `isRestorable = false` to keep AppKit's autosave as the only mechanism (otherwise Cocoa state restoration would override it after `awakeFromNib`).

**Windows** *(when added)* — `windows/runner/flutter_window.cpp` → `SetUpWindowStatePersistence()`. Use `WINDOWPLACEMENT` (covers normal-rect + maximized / minimized state in one struct) read & written under `HKCU\Software\InvoiceNinja\Window`. Persist on `WM_MOVE` / `WM_SIZE` / `WM_DESTROY`; restore in `OnCreate` via `SetWindowPlacement`. For fullscreen (Windows has no built-in fullscreen — it's a borderless window covering the monitor), persist a separate `Fullscreen` DWORD.

**Linux** *(when added)* — `linux/runner/my_application.cc` → `setup_window_state_persistence()`. Connect `configure-event` (geometry) and `window-state-event` (fullscreen / maximize); persist to `~/.config/invoice_ninja/window-state.ini` via `GKeyFile`. Restore in `activate` via `gtk_window_set_default_size` + `gtk_window_move` + `gtk_window_fullscreen` as appropriate.
