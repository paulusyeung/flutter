import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:admin/ui/features/settings/views/advanced/invoice_design/bodies/custom_designs_body.dart';
import 'package:admin/ui/features/settings/widgets/settings_screen_scaffold.dart';

/// Standalone Custom Designs screen — `/settings/invoice_design/custom_designs`.
///
/// Custom Designs is no longer an Invoice Design tab; it's reached from the
/// "Custom Designs" entry on the General Settings tab (or its own URL). The
/// screen is a thin chrome wrapper around the already-self-contained
/// [CustomDesignsBody] (it reads `Services` off Provider, watches the designs
/// stream, and pushes `DesignEditScreen` itself — no VM/cascade wiring).
///
/// It's reached via `context.go` (a flat leaf route, no Navigator entry to
/// pop) and has no Save button, so it supplies an explicit back affordance —
/// otherwise wide layouts (`SettingsScreenScaffold` shows no leading there)
/// would strand the user with no way back to Invoice Design.
class CustomDesignsScreen extends StatelessWidget {
  const CustomDesignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      titleKey: 'custom_designs',
      leading: BackButton(
        onPressed: () => context.go('/settings/invoice_design'),
      ),
      body: const CustomDesignsBody(),
    );
  }
}
