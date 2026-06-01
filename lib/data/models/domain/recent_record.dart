import 'package:admin/domain/entity_type.dart';

/// One "recently-viewed entity" entry, surfaced as the command palette's
/// "Recent" group. Deliberately tiny + plain — it's persisted as a JSON
/// array in `nav_state.recent_entities_json`, scoped to the active company
/// (cleared on company switch / logout, same as the nav history).
class RecentRecord {
  const RecentRecord({
    required this.type,
    required this.id,
    required this.label,
    required this.viewedAt,
  });

  final EntityType type;

  /// Server (or `tmp_<uuid>` offline-create) entity id. Routed through
  /// `goEntityRecord(context, type, id)` on selection.
  final String id;

  /// Human label resolved at capture time (e.g. a client's display name or
  /// `#<invoice number>`). Stored so the palette needn't re-resolve it.
  final String label;

  final DateTime viewedAt;

  /// Same entity iff same type + id. Used to de-dupe / move-to-front.
  bool sameEntity(RecentRecord other) => other.type == type && other.id == id;

  Map<String, Object?> toJson() => {
    't': type.name,
    'i': id,
    'l': label,
    'v': viewedAt.millisecondsSinceEpoch,
  };

  /// Returns `null` for an unparseable/legacy row (unknown enum name, missing
  /// id) so a single bad entry can't poison the whole list on restore.
  static RecentRecord? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final typeName = raw['t'];
    final id = raw['i'];
    if (typeName is! String || id is! String || id.isEmpty) return null;
    final type = EntityType.values
        .where((e) => e.name == typeName)
        .cast<EntityType?>()
        .firstWhere((_) => true, orElse: () => null);
    if (type == null) return null;
    final v = raw['v'];
    return RecentRecord(
      type: type,
      id: id,
      label: raw['l'] is String ? raw['l'] as String : '',
      viewedAt: DateTime.fromMillisecondsSinceEpoch(v is int ? v : 0),
    );
  }
}
