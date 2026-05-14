import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:admin/data/models/domain/user.dart';
import 'package:admin/data/repositories/auth_repository.dart';
import 'package:admin/data/repositories/user_repository.dart';

/// Resolves the active per-(company, user) accent colour and exposes it as a
/// `ValueListenable<Color?>` so `MaterialApp.router` can rebuild the theme
/// whenever the user switches companies or saves a new swatch.
///
/// Listens to two upstream sources:
///   - [AuthRepository.session] — re-subscribes to a fresh [UserRepository]
///     stream every time `currentCompanyId` changes (or the user signs out).
///   - [UserRepository.watch] for the current `(companyId, userId)` pair —
///     reads `companyUserSettings.accentColor` off each emission.
///
/// Also exposes [setPreview] so the Settings > User Details > Preferences
/// picker can flip the theme live as the user clicks a swatch, before the
/// Save round-trip lands. The preview supersedes the persisted value until
/// the watched user emits a row whose accent matches (server-confirmed) or
/// the session switches.
///
/// `value` is `null` when no override applies; consumers fall back to the
/// default `InTheme.accent` token (the v2 blue).
class AccentColorController extends ChangeNotifier
    implements ValueListenable<Color?> {
  AccentColorController({required this.auth, required this.users}) {
    auth.session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  final AuthRepository auth;
  final UserRepository users;

  Color? _persisted;
  Color? _preview;
  String? _watchedCompanyId;
  String? _watchedUserId;
  StreamSubscription<User?>? _userSub;

  @override
  Color? get value => _preview ?? _persisted;

  /// Live-preview override used by the swatch picker. The value takes
  /// precedence over the persisted server state until the watched user
  /// emits a row whose accent matches (Save round-tripped) or the session
  /// switches. Pass `null` to drop the preview (Reset button).
  void setPreview(Color? color) {
    if (_preview == color) return;
    final prev = value;
    _preview = color;
    if (value != prev) notifyListeners();
  }

  void _onSessionChanged() {
    final session = auth.session.value;
    final companyId = session?.currentCompanyId ?? '';
    final userId = session?.userId ?? '';
    if (companyId == _watchedCompanyId && userId == _watchedUserId) return;
    _watchedCompanyId = companyId;
    _watchedUserId = userId;
    _userSub?.cancel();
    _userSub = null;
    final prev = value;
    _preview = null;
    if (companyId.isEmpty || userId.isEmpty) {
      _persisted = null;
      if (value != prev) notifyListeners();
      return;
    }
    if (value != prev) notifyListeners();
    _userSub = users
        .watch(companyId: companyId, userId: userId)
        .listen(
          _onUserEmitted,
          onError: (Object _, StackTrace _) {
            _setPersisted(null);
          },
        );
  }

  void _onUserEmitted(User? user) {
    _setPersisted(_parseHex(user?.companyUserSettings.accentColor));
  }

  void _setPersisted(Color? next) {
    final prev = value;
    _persisted = next;
    if (_preview != null && _preview == next) _preview = null;
    if (value != prev) notifyListeners();
  }

  @override
  void dispose() {
    auth.session.removeListener(_onSessionChanged);
    _userSub?.cancel();
    super.dispose();
  }

  /// Parses `#RRGGBB` / `#AARRGGBB` (case-insensitive). Returns `null` for
  /// empty / malformed input so the theme falls back to the default token.
  static Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6 && cleaned.length != 8) return null;
    final raw = int.tryParse(cleaned, radix: 16);
    if (raw == null) return null;
    return Color(cleaned.length == 6 ? 0xFF000000 | raw : raw);
  }
}
