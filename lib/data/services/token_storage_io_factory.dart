import 'package:admin/data/services/token_storage.dart';

/// Native production token store: the hardened `flutter_secure_storage`
/// wrapper. Behavior is unchanged from before the web seam existed.
TokenStorage defaultTokenStorage() => SecureTokenStorage();
