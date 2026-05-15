import 'package:admin/ui/features/tokens/views/token_list_screen.dart';

/// Settings → Integrations → API Tokens. Re-export so the settings router
/// keeps importing this single path; the real list lives under
/// `lib/ui/features/tokens/...`.
typedef IntegrationsApiTokensScreen = TokenListScreen;
