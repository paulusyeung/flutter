/// Parsed `/api/v1/preimport` response for a single entity import.
///
/// Wire shape (verified against React `UploadImport.tsx`):
/// ```json
/// { "hash": "<id>",
///   "mappings": {
///     "<entity>": {
///       "headers": [["Col A","Col B"], ["sample a","sample b"]],
///       "available": ["client.name","client.email", ...],
///       "hints": [0, 5, -1, ...]   // optional, aligned to columns
///     } } }
/// ```
class ImportPreview {
  const ImportPreview({
    required this.hash,
    required this.entity,
    required this.columns,
    required this.sample,
    required this.available,
    required this.hints,
  });

  /// Transaction id echoed back on the `/api/v1/import` submit.
  final String hash;

  /// Entity key (`client`, `invoice`, …) — same value sent to preimport.
  final String entity;

  /// CSV header names, in column order.
  final List<String> columns;

  /// First data row (parallel to [columns]); empty when not provided.
  final List<String> sample;

  /// Dotted field paths the user can map a column onto
  /// (`client.name`, `client.email`, …).
  final List<String> available;

  /// Server's best-guess mapping: `hints[i]` is an index into [available]
  /// for column `i`, or -1 / out-of-range when it has no guess.
  final List<int> hints;

  factory ImportPreview.fromJson(
    Map<String, dynamic> json,
    String entity,
  ) {
    String hash = '';
    final h = json['hash'];
    if (h is String) {
      hash = h;
    } else {
      final data = json['data'];
      if (data is Map && data['hash'] is String) {
        hash = data['hash'] as String;
      }
    }

    final mappings = json['mappings'];
    Map<String, dynamic> entityMap = const {};
    if (mappings is Map && mappings[entity] is Map) {
      entityMap = Map<String, dynamic>.from(mappings[entity] as Map);
    }

    final headers = entityMap['headers'];
    var columns = <String>[];
    var sample = <String>[];
    if (headers is List && headers.isNotEmpty) {
      final row0 = headers[0];
      if (row0 is List) columns = row0.map((e) => '$e').toList();
      if (headers.length > 1 && headers[1] is List) {
        sample = (headers[1] as List).map((e) => '$e').toList();
      }
    }

    final avail = entityMap['available'];
    final available = avail is List
        ? avail.map((e) => '$e').toList(growable: false)
        : const <String>[];

    final hintsRaw = entityMap['hints'];
    final hints = hintsRaw is List
        ? hintsRaw
              .map((e) => e is int ? e : int.tryParse('$e') ?? -1)
              .toList(growable: false)
        : const <int>[];

    return ImportPreview(
      hash: hash,
      entity: entity,
      columns: columns,
      sample: sample,
      available: available,
      hints: hints,
    );
  }
}
