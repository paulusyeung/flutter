import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';

/// Ensures `Services.statics` is loaded before its child reads from it.
///
/// `main.dart` warms statics at boot, but a fresh login that lands directly
/// on a settings screen with statics-backed dropdowns (Size / Industry on
/// Company Details; Currency / Language / Timezone / Date Format on
/// Localization) before the first `/api/v1/statics` fetch finishes would see
/// empty maps. Plain `ensureLoaded()` (no force) reads from the Drift cache
/// when available and only hits the network when the cache is stale or
/// absent; the `setState(() {})` on completion forces a rebuild so the
/// dropdowns re-read `Services.statics`.
///
/// All maps in the statics payload land together (`/api/v1/statics` returns
/// one envelope), so `statics.currencies.isEmpty` is a reliable
/// "not loaded yet" proxy for every consumer.
class StaticsWarmer extends StatefulWidget {
  const StaticsWarmer({super.key, required this.child});

  final Widget child;

  @override
  State<StaticsWarmer> createState() => _StaticsWarmerState();
}

class _StaticsWarmerState extends State<StaticsWarmer> {
  @override
  void initState() {
    super.initState();
    final statics = context.read<Services>().statics;
    if (statics.currencies.isEmpty) {
      statics.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
