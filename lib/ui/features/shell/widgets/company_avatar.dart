import 'package:flutter/material.dart';

import 'package:admin/ui/core/widgets/avatar_tint.dart';
import 'package:admin/utils/url_safety.dart';

/// Small rounded square showing the first letters of [name], tinted with a
/// stable colour derived from [seed]. Used wherever the design system shows
/// a company "logo" — sidebar header, picker rows, mobile top bar.
///
/// When [logoUrl] is non-null, the uploaded logo is drawn on top of the
/// tinted square; the initials still render underneath so a transparent or
/// slow-loading logo never leaves an empty box.
class CompanyAvatar extends StatelessWidget {
  const CompanyAvatar({
    required this.name,
    required this.seed,
    this.size = 28,
    this.logoUrl,
    super.key,
  });

  /// Source for the initials. Falls back to '?' when empty.
  final String name;

  /// Stable input for the tint colour. Usually the company id.
  final String seed;

  final double size;

  /// Optional uploaded logo URL. When the image fails to load or is still
  /// loading, the initials underneath remain visible.
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final tint = avatarTintFor(seed);
    final initials = _initialsFor(name);
    final radius = BorderRadius.circular(size * 0.32);

    Widget initialsBox() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint, borderRadius: radius),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
    );

    // Treat unsafe URLs as if no logo was set — the initials fallback handles
    // both "no logo" and "server returned a hostile URL" the same way.
    if (!isSafeHttpsUrl(logoUrl)) return initialsBox();

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => initialsBox(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : initialsBox(),
        ),
      ),
    );
  }
}

String _initialsFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    final s = parts.first;
    return s.characters
        .take(s.runes.length >= 2 ? 2 : 1)
        .toString()
        .toUpperCase();
  }
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}
