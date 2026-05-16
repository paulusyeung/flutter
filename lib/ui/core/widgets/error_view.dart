import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/widget_preview_support.dart';

/// Shared error display. Every screen that surfaces a load error uses this
/// instead of bare red text, so the affordance (`Retry`) is consistent.
class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // SingleChildScrollView so the icon + text + retry button shrink
    // gracefully when the surrounding card is too short — dashboard cards
    // give error states a fixed height that can't fit the full column on
    // small viewports.
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(context.tr('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No-retry preview. The retry variant needs `context.tr('retry')` which
/// requires the `Localization` ancestor — wire that up only if the previewer
/// gains a real localization story for this app.
@Preview(name: 'Message only', group: 'ErrorView', theme: appPreviewTheme)
Widget previewErrorView() {
  return const ErrorView(
    message: 'Could not load clients. Check your connection and try again.',
  );
}
