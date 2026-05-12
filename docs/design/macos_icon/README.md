# macOS `.icon` source assets (parked)

This folder holds source assets for the future Liquid Glass icon migration
(macOS 26 / Xcode 26 `.icon` bundle format). Nothing here is consumed at
runtime — these are design inputs for **Icon Composer.app** (ships inside
Xcode at `/Applications/Xcode.app/Contents/Applications/Icon Composer.app`).

## Files

- `envelope.png` — Invoice Ninja envelope glyph, white on transparent,
  1024×1024 RGBA, centred at ~78% canvas width. Extracted from the
  shipping `app_icon_1024.png` via luminance threshold so it matches the
  brand's existing envelope strokes pixel-for-pixel.

## When you pick this back up

1. Open Icon Composer:
   `open "/Applications/Xcode.app/Contents/Applications/Icon Composer.app"`
2. **File → New** → drag `envelope.png` onto the foreground/glyph layer slot.
3. Set the background fill to flat black (`#000000`).
4. Leave specular, shadow, and translucency at their Liquid Glass defaults.
5. **File → Save As…** →
   `macos/Runner/Assets.xcassets/AppIcon.icon`.
6. Delete `macos/Runner/Assets.xcassets/AppIcon.appiconset/` so there's only
   one asset named `AppIcon` in the catalog.
7. Rebuild and check `Assets.car` via `assetutil --info` for an actual
   `.icon` rendition (this is the step that failed last time).

## Known blocker

As of Xcode 26.4.1 (May 2026), `actool` accepts `.icon` bundles inside the
asset catalog but emits no rendition — the build runs cleanly and the dock
falls back to the blueprint placeholder. Two contributing factors:

- The project's `MACOSX_DEPLOYMENT_TARGET = 10.15` (see three matches in
  `macos/Runner.xcodeproj/project.pbxproj`) is below the macOS 15.4+
  floor the `.icon` format needs.
- The `man actool` page on Xcode 26.4 still only documents `.appiconset`
  / `.iconset`; the asset-catalog tool hasn't caught up with the Icon
  Composer GUI.

Recheck after each Xcode update; the migration becomes a one-line
deployment-target bump + a rebuild once Apple closes the tooling gap.

## Reference assets

- Canonical brand wordmark: `assets/images/logo_dark.png` /
  `assets/images/logo_light.png` (436×102, used at runtime in the app
  UI — not as the macOS app icon).
- Current shipping macOS icon set:
  `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (envelope on bevel
  coin, 826/1024 macOS HIG-squircle, same design that ships in the
  legacy admin-portal Flutter app).
