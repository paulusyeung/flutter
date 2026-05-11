import 'package:flutter/material.dart';

/// Invoice Ninja v2 design tokens. The single source of truth for the
/// visual language; the JSX equivalent lives at `docs/design/v2/tokens.jsx`.
///
/// Read tokens through `context.inTheme.<name>` — the [BuildContext]
/// extension below resolves to the brightness-appropriate variant
/// automatically.
class InTheme extends ThemeExtension<InTheme> {
  const InTheme({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.accentLime,
    required this.rail,
    required this.railInk,
    required this.railInk2,
    required this.paid,
    required this.paidSoft,
    required this.overdue,
    required this.overdueSoft,
    required this.draft,
    required this.draftSoft,
    required this.sent,
    required this.sentSoft,
    required this.partial,
    required this.partialSoft,
    required this.shadow1,
    required this.shadow2,
  });

  // Surfaces.
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color borderStrong;

  // Ink (four tones).
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;

  // Accent.
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color accentLime;

  // Sidebar rail.
  final Color rail;
  final Color railInk;
  final Color railInk2;

  // Status pairs (the saturated tone + its soft background variant).
  final Color paid;
  final Color paidSoft;
  final Color overdue;
  final Color overdueSoft;
  final Color draft;
  final Color draftSoft;
  final Color sent;
  final Color sentSoft;
  final Color partial;
  final Color partialSoft;

  // Elevation. Stored on the tokens because dark mode wants softer shadows.
  final List<BoxShadow> shadow1;
  final List<BoxShadow> shadow2;

  /// Light preset — direct port of `tokens.jsx`.
  static const InTheme light = InTheme(
    bg: Color(0xFFF6F4EF),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFFBF9F4),
    border: Color(0xFFE8E3D8),
    borderStrong: Color(0xFFD6CFBF),
    ink: Color(0xFF1A1814),
    ink2: Color(0xFF4A4540),
    ink3: Color(0xFF857F73),
    ink4: Color(0xFFB5AE9F),
    accent: Color(0xFF1F8A5B),
    accentInk: Color(0xFF0E4A30),
    accentSoft: Color(0xFFE3F3EA),
    accentLime: Color(0xFFA8E22F),
    rail: Color(0xFF15140F),
    railInk: Color(0xFFE8E5DC),
    railInk2: Color(0xFF8A8678),
    paid: Color(0xFF1F8A5B),
    paidSoft: Color(0xFFE3F3EA),
    overdue: Color(0xFFC0392B),
    overdueSoft: Color(0xFFF9E6E2),
    draft: Color(0xFF857F73),
    draftSoft: Color(0xFFEDEAE2),
    sent: Color(0xFFB07A1F),
    sentSoft: Color(0xFFF6EBD3),
    partial: Color(0xFF2A6FDB),
    partialSoft: Color(0xFFE2ECFB),
    shadow1: [
      BoxShadow(
        color: Color(0x0F14120C), // rgba(20,18,12,.06)
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    shadow2: [
      BoxShadow(
        color: Color(0x1414120C), // rgba(20,18,12,.08)
        offset: Offset(0, 4),
        blurRadius: 16,
      ),
      BoxShadow(
        color: Color(0x0A14120C), // rgba(20,18,12,.04)
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
  );

  /// Dark preset — derived from the light tokens. The source `tokens.jsx`
  /// doesn't define dark, so we anchor on `rail` (`#15140F`, already the
  /// design system's "deep ink") and stay in the warm-tone family.
  static const InTheme dark = InTheme(
    bg: Color(0xFF15140F),
    surface: Color(0xFF1F1E18),
    surfaceAlt: Color(0xFF28261F),
    border: Color(0xFF2E2B22),
    borderStrong: Color(0xFF3A362B),
    ink: Color(0xFFF6F4EF),
    ink2: Color(0xFFC8C2B5),
    ink3: Color(0xFF857F73), // perceptually mid — unchanged
    ink4: Color(0xFF5A554B),
    accent: Color(0xFF1F8A5B),
    accentInk: Color(0xFF6BD9A0), // lighter for dark active states
    accentSoft: Color(0xFF1A3A2A),
    accentLime: Color(0xFFA8E22F),
    rail: Color(0xFF0A0907), // nudged darker so it differs from bg
    railInk: Color(0xFFE8E5DC),
    railInk2: Color(0xFF8A8678),
    paid: Color(0xFF1F8A5B),
    paidSoft: Color(0xFF1A3A2A),
    overdue: Color(0xFFE66055), // brighter for dark legibility
    overdueSoft: Color(0xFF3A1F1C),
    draft: Color(0xFFB5AE9F),
    draftSoft: Color(0xFF28261F),
    sent: Color(0xFFD49C42),
    sentSoft: Color(0xFF3A2D18),
    partial: Color(0xFF5994E8),
    partialSoft: Color(0xFF1B2A47),
    shadow1: [
      BoxShadow(
        color: Color(0x4D000000), // rgba(0,0,0,.30)
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    shadow2: [
      BoxShadow(
        color: Color(0x66000000), // rgba(0,0,0,.40)
        offset: Offset(0, 4),
        blurRadius: 16,
      ),
      BoxShadow(
        color: Color(0x33000000), // rgba(0,0,0,.20)
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
  );

  @override
  InTheme copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? borderStrong,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? ink4,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? accentLime,
    Color? rail,
    Color? railInk,
    Color? railInk2,
    Color? paid,
    Color? paidSoft,
    Color? overdue,
    Color? overdueSoft,
    Color? draft,
    Color? draftSoft,
    Color? sent,
    Color? sentSoft,
    Color? partial,
    Color? partialSoft,
    List<BoxShadow>? shadow1,
    List<BoxShadow>? shadow2,
  }) {
    return InTheme(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      ink4: ink4 ?? this.ink4,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      accentLime: accentLime ?? this.accentLime,
      rail: rail ?? this.rail,
      railInk: railInk ?? this.railInk,
      railInk2: railInk2 ?? this.railInk2,
      paid: paid ?? this.paid,
      paidSoft: paidSoft ?? this.paidSoft,
      overdue: overdue ?? this.overdue,
      overdueSoft: overdueSoft ?? this.overdueSoft,
      draft: draft ?? this.draft,
      draftSoft: draftSoft ?? this.draftSoft,
      sent: sent ?? this.sent,
      sentSoft: sentSoft ?? this.sentSoft,
      partial: partial ?? this.partial,
      partialSoft: partialSoft ?? this.partialSoft,
      shadow1: shadow1 ?? this.shadow1,
      shadow2: shadow2 ?? this.shadow2,
    );
  }

  @override
  InTheme lerp(ThemeExtension<InTheme>? other, double t) {
    if (other is! InTheme) return this;
    return InTheme(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      ink4: Color.lerp(ink4, other.ink4, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentLime: Color.lerp(accentLime, other.accentLime, t)!,
      rail: Color.lerp(rail, other.rail, t)!,
      railInk: Color.lerp(railInk, other.railInk, t)!,
      railInk2: Color.lerp(railInk2, other.railInk2, t)!,
      paid: Color.lerp(paid, other.paid, t)!,
      paidSoft: Color.lerp(paidSoft, other.paidSoft, t)!,
      overdue: Color.lerp(overdue, other.overdue, t)!,
      overdueSoft: Color.lerp(overdueSoft, other.overdueSoft, t)!,
      draft: Color.lerp(draft, other.draft, t)!,
      draftSoft: Color.lerp(draftSoft, other.draftSoft, t)!,
      sent: Color.lerp(sent, other.sent, t)!,
      sentSoft: Color.lerp(sentSoft, other.sentSoft, t)!,
      partial: Color.lerp(partial, other.partial, t)!,
      partialSoft: Color.lerp(partialSoft, other.partialSoft, t)!,
      // Shadows don't lerp cleanly when their list lengths match; we just
      // snap at the halfway point — the visual difference between light and
      // dark shadow alpha is subtle enough that this isn't noticeable.
      shadow1: t < 0.5 ? shadow1 : other.shadow1,
      shadow2: t < 0.5 ? shadow2 : other.shadow2,
    );
  }
}

/// Reads the brightness-appropriate tokens from the current [Theme].
extension InThemeContext on BuildContext {
  InTheme get inTheme => Theme.of(this).extension<InTheme>()!;
}

/// Brightness-independent dimensions — corner radii.
class InRadii {
  InRadii._();

  static const double r1 = 6;
  static const double r2 = 10;
  static const double r3 = 14;
  static const double r4 = 20;
}

/// Brightness-independent dimensions — spacing scale.
class InSpacing {
  InSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}
