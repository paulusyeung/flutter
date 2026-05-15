import 'dart:typed_data';

import 'package:admin/data/models/domain/company_settings.dart';
import 'package:admin/data/services/api_client.dart';

/// Wraps `POST /api/v1/live_design` — the server-side preview renderer
/// behind the Invoice Design page's Preview pane.
///
/// Response shape is raw PDF bytes (`content-type: application/pdf`), so we
/// route through [ApiClient.postRaw] (which validates the content-type to
/// guard against a misrouted JSON-error envelope being handed to a PDF
/// renderer).
///
/// The payload mirrors React's `pages/general-settings/components/
/// GeneralSettings.tsx` and admin-portal's `settings_model.dart:1080-1114`:
/// `entity_type` + a snapshot of the current settings + the scope identifiers
/// so previews at client / group scope render the cascade-merged result.
class LiveDesignService {
  LiveDesignService(this._apiClient);

  final ApiClient _apiClient;

  /// Render a single PDF preview for the current draft settings.
  ///
  /// - [entityType] one of `invoice` / `quote` / `credit` / `purchase_order`.
  /// - [settings] the **draft** settings (overlay applied) — pass
  ///   `host.settings`.
  /// - [settingsType] cascade level: `'company'` / `'group'` / `'client'`.
  /// - [groupId] required when [settingsType] = `'group'`.
  /// - [clientId] required when [settingsType] = `'client'`.
  /// - [entityId] when previewing a specific record; usually null for the
  ///   settings screen's generic preview.
  Future<Uint8List> renderPreview({
    required String entityType,
    required CompanySettings settings,
    String settingsType = 'company',
    String? groupId,
    String? clientId,
    String? entityId,
  }) {
    final payload = <String, dynamic>{
      'entity_type': entityType,
      'settings_type': settingsType,
      'settings': settings.toJson(),
      if (groupId != null) 'group_id': groupId,
      if (clientId != null) 'client_id': clientId,
      if (entityId != null) 'entity_id': entityId,
    };
    return _apiClient.postRaw(
      '/api/v1/live_design',
      body: payload,
      // Live preview is a read-equivalent operation — the server doesn't
      // persist anything. Allow it through demo mode so the demo account
      // can still preview design changes.
      readOnly: true,
    );
  }
}
