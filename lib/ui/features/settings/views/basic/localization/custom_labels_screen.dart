import 'package:flutter/material.dart';

import 'package:admin/ui/features/settings/views/placeholder_settings_screen.dart';

class LocalizationCustomLabelsScreen extends StatelessWidget {
  const LocalizationCustomLabelsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderSettingsScreen(titleKey: 'custom_labels');
}
