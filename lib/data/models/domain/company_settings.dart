import 'package:admin/data/models/api/company_settings_api_model.dart';

/// Domain `CompanySettings` is the same shape as the wire model — every
/// field is nullable, every name is the camelCase mirror of the server key,
/// and there's no entity-specific transformation to do (no money/date types
/// that need lifting, no derived fields). Typedefing keeps the UI from
/// caring about the `*Api` suffix while avoiding the boilerplate of
/// re-declaring ~200 fields in a second freezed class.
///
/// A `null` field means "not set on this entity; inherit via the cascade
/// (group → company)." At company level the UI treats null as empty; at
/// group/client level it shows the inherited value as a placeholder and
/// renders an override checkbox via [OverridableField].
typedef CompanySettings = CompanySettingsApi;
