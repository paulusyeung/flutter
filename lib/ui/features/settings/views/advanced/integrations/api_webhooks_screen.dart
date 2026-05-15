import 'package:admin/ui/features/webhooks/views/webhook_list_screen.dart';

/// Settings → Integrations → API Webhooks. Re-export so the settings router
/// keeps importing this single path; the real list lives under
/// `lib/ui/features/webhooks/...`.
typedef IntegrationsApiWebhooksScreen = WebhookListScreen;
