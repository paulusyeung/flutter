import 'package:flutter/material.dart';

/// Curated set of icons a user can assign to a saved view.
///
/// Keys are stable strings persisted in `saved_views.icon`; values are
/// **`const` tear-offs of real Material constants** so Flutter's icon
/// tree-shaking stays enabled. Never construct `IconData(0x..., fontFamily:
/// 'MaterialIcons')` dynamically here — that disables tree-shaking app-wide
/// and bloats the bundle.
///
/// Insertion order is the picker's display order. Keep this ≲ 24 entries —
/// beyond that the grid becomes a scroll-hunt.
const Map<String, IconData> kSavedViewIcons = {
  'bookmark': Icons.bookmark_outline,
  'star': Icons.star_outline,
  'flag': Icons.flag_outlined,
  'filter': Icons.filter_alt_outlined,
  'folder': Icons.folder_outlined,
  'inbox': Icons.inbox_outlined,
  'archive': Icons.archive_outlined,
  'check': Icons.check_circle_outline,
  'schedule': Icons.schedule,
  'calendar': Icons.calendar_today,
  'payments': Icons.payments_outlined,
  'receipt': Icons.receipt_long_outlined,
  'warning': Icons.warning_amber_outlined,
  'bolt': Icons.bolt,
  'label': Icons.label_outline,
  'people': Icons.people_outline,
  'trash': Icons.delete_outline,
  'pin': Icons.push_pin_outlined,
  'favorite': Icons.favorite_outline,
  'done_all': Icons.done_all,
};

/// Default icon for a saved view with no custom selection. Preserved from the
/// feature's original hardcoded look — a bookmark reads as "this is a saved
/// view", not the entity's own nav icon.
const IconData kSavedViewDefaultIcon = Icons.bookmark_outline;

/// Resolve a persisted icon key to its [IconData]. Unknown / null keys fall
/// back to [kSavedViewDefaultIcon], so a removed key never blanks a row.
IconData savedViewIcon(String? key) =>
    kSavedViewIcons[key] ?? kSavedViewDefaultIcon;
