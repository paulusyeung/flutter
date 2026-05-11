import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/services.dart';

/// Rendered when the server's `x-minimum-client-version` exceeds our
/// `kClientVersion`. No Retry — the next request would just bounce the same
/// way. The user's only useful actions are "update the app" (out of band)
/// and "sign out" (in case they want to point at a different server).
class ClientTooOldScreen extends StatelessWidget {
  const ClientTooOldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<({String minRequired, String current})?>(
          valueListenable: services.clientTooOld,
          builder: (context, info, _) {
            final theme = Theme.of(context);
            final min = info?.minRequired ?? '?';
            final current = info?.current ?? '?';
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.system_update_alt,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Update required',
                        style: theme.textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Invoice Ninja client is at v$current. '
                        'This server requires at least v$min. '
                        'Please update from the App Store and try again.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign out'),
                        onPressed: () async {
                          // Clear the too-old flag first so the router can
                          // redirect cleanly to /login after logout completes.
                          services.clientTooOld.value = null;
                          await services.auth.logout();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
