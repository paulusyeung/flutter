import 'package:flutter_test/flutter_test.dart';

import 'package:admin/data/models/api/health_check_api_model.dart';

void main() {
  group('HealthCheckResponse.fromJson', () {
    test('maps is_docker → isDocker', () {
      // The server reports `is_docker`; the dialog gates the Docker-only
      // false-positive warnings on it. Older code hardcoded this to false.
      expect(
        HealthCheckResponse.fromJson({'is_docker': true}).isDocker,
        isTrue,
      );
      expect(
        HealthCheckResponse.fromJson({'is_docker': false}).isDocker,
        isFalse,
      );
    });

    test('maps pending_migrations (plural) → pendingMigration', () {
      // Server key is plural; the singular key never matched, so the
      // "pending migrations" warning silently never fired.
      expect(
        HealthCheckResponse.fromJson({
          'pending_migrations': true,
        }).pendingMigration,
        isTrue,
      );
      // The old singular key must NOT satisfy the field.
      expect(
        HealthCheckResponse.fromJson({
          'pending_migration': true,
        }).pendingMigration,
        isFalse,
      );
    });

    test('maps env_writable → envWritable', () {
      expect(
        HealthCheckResponse.fromJson({'env_writable': false}).envWritable,
        isFalse,
      );
      expect(
        HealthCheckResponse.fromJson({'env_writable': true}).envWritable,
        isTrue,
      );
    });

    test('defaults are safe for an empty payload', () {
      final r = HealthCheckResponse.fromJson(<String, dynamic>{});
      expect(r.isDocker, isFalse);
      expect(r.pendingMigration, isFalse);
      expect(r.envWritable, isFalse);
      expect(r.systemHealth, isFalse);
    });
  });
}
