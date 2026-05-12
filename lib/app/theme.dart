import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:admin/app/design_tokens.dart';

/// External URLs the login screen needs.
const String kSignupUrl = 'https://invoiceninja.com';
const String kStatusUrl = 'https://status.invoiceninja.com';

/// Builds the v2 design-system [ThemeData] for the given palette.
///
/// All variants share radii, spacing, and Inter Tight typography; the
/// colors come from the [InTheme] argument and are attached as a
/// `ThemeExtension` so widgets can read them via `context.inTheme.<name>`.
/// Brightness is derived from the tokens so this stays a pure function of
/// the palette — callers don't need to keep brightness in sync.
ThemeData buildInTheme(InTheme tokens) {
  final brightness = tokens.brightness;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: tokens.accent,
    onPrimary: Colors.white,
    secondary: tokens.ink,
    onSecondary: tokens.surface,
    tertiary: tokens.accentLime,
    onTertiary: tokens.ink,
    error: tokens.overdue,
    onError: Colors.white,
    surface: tokens.surface,
    onSurface: tokens.ink,
    surfaceContainerHighest: tokens.surfaceAlt,
    outline: tokens.border,
    outlineVariant: tokens.borderStrong,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.bg,
    canvasColor: tokens.bg,
    dividerColor: tokens.border,
    extensions: [tokens],
  );

  // The v2 design system specifies Geist as the primary sans, with Inter
  // Tight as its declared fallback. `google_fonts` 6.2.1 doesn't expose
  // Geist, so we use Inter Tight — same geometric-humanist family.
  final textTheme = GoogleFonts.interTightTextTheme(
    base.textTheme,
  ).apply(bodyColor: tokens.ink, displayColor: tokens.ink);

  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,

    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: textTheme.bodyMedium?.copyWith(color: tokens.ink3),
      floatingLabelStyle: textTheme.bodySmall?.copyWith(color: tokens.ink2),
      hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.ink4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(InRadii.r2),
        borderSide: BorderSide(color: tokens.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(InRadii.r2),
        borderSide: BorderSide(color: tokens.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(InRadii.r2),
        borderSide: BorderSide(color: tokens.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(InRadii.r2),
        borderSide: BorderSide(color: tokens.overdue),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(InRadii.r2),
        borderSide: BorderSide(color: tokens.overdue, width: 1.5),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tokens.accent,
        foregroundColor: Colors.white,
        // `Size.fromHeight(44)` is `Size(double.infinity, 44)` — full-width by
        // default. Fine for Column-stacked form buttons (login, settings);
        // crashes inside a `Row` (Row gives non-flex children unbounded
        // `maxWidth`, which the button then tries to enforce). When putting
        // a FilledButton in a Row, override per-call with e.g.
        // `style: FilledButton.styleFrom(minimumSize: const Size(64, 44))`.
        minimumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadii.r2),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.ink,
        side: BorderSide(color: tokens.border),
        // See FilledButton note above — `Size.fromHeight(40)` is
        // `Size(double.infinity, 40)` and crashes inside a Row.
        minimumSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadii.r2),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: tokens.ink2,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),

    cardTheme: CardThemeData(
      color: tokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: tokens.border),
        borderRadius: BorderRadius.circular(InRadii.r3),
      ),
      margin: EdgeInsets.zero,
    ),

    // M3's default `SegmentedButton` silhouette is a `StadiumBorder` (pill).
    // The v2 design system uses rounded rectangles for every button family —
    // mirror the `InRadii.r2` corner used by `FilledButton` / `OutlinedButton`
    // above so all the button shapes line up. Per-widget `style` still wins
    // via Flutter's effectiveValue chain, so individual call sites can still
    // override (e.g. ThemeTile's per-segment minimumSize for uniform width).
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InRadii.r2),
        ),
      ),
    ),

    // Snackbar styling lives in `lib/ui/core/widgets/notify.dart` — the
    // `Notify.success/error/warning/info` helpers render their own card and
    // pass `backgroundColor: transparent` so the shell here just controls
    // float + rounded shape for any direct `SnackBar` usage that bypasses
    // the helper.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(InRadii.r2),
      ),
    ),
  );
}
