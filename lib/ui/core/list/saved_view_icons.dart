import 'package:flutter/material.dart';

/// Curated set of icons a user can assign to a saved view.
///
/// Keys are stable strings persisted in `saved_views.icon`; values are
/// **`const` tear-offs of real Material constants** so Flutter's icon
/// tree-shaking stays enabled. Never construct `IconData(0x..., fontFamily:
/// 'MaterialIcons')` dynamically here — that disables tree-shaking app-wide
/// and bloats the bundle.
///
/// Insertion order is the picker's display order; the picker scrolls
/// (`showSavedViewIconPicker`), so the list can grow. **Never rename or
/// remove a shipped key** — a persisted `iconKey` whose entry disappears
/// silently falls back to the default bookmark via [savedViewIcon], losing
/// the user's choice. Only append. (The sole exception is a key whose icon
/// *is* [kSavedViewDefaultIcon]: removing it is visually lossless because
/// the fallback renders the same glyph — see the dropped `'bookmark'`.)
const Map<String, IconData> kSavedViewIcons = {
  // — original set —
  // (No 'bookmark' entry: that icon is the Default tile, so listing it here
  // too would show the bookmark twice. A legacy `iconKey: 'bookmark'` row
  // resolves to the identical bookmark via savedViewIcon's default
  // fallback, so dropping the key is visually lossless.)
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
  // — finance / business —
  'money': Icons.attach_money,
  'credit_card': Icons.credit_card,
  'account_balance': Icons.account_balance_outlined,
  'cart': Icons.shopping_cart_outlined,
  'trending_up': Icons.trending_up,
  'trending_down': Icons.trending_down,
  'pie_chart': Icons.pie_chart_outline,
  'bar_chart': Icons.bar_chart,
  'description': Icons.description_outlined,
  'business': Icons.business_outlined,
  'work': Icons.work_outline,
  // — status / priority —
  'priority_high': Icons.priority_high,
  'error': Icons.error_outline,
  'info': Icons.info_outline,
  'help': Icons.help_outline,
  'block': Icons.block,
  'pending': Icons.pending_outlined,
  'hourglass': Icons.hourglass_empty,
  'verified': Icons.verified_outlined,
  'thumb_up': Icons.thumb_up_outlined,
  // — organization / nav —
  'home': Icons.home_outlined,
  'dashboard': Icons.dashboard_outlined,
  'list': Icons.list_alt_outlined,
  'grid': Icons.grid_view_outlined,
  'category': Icons.category_outlined,
  'visibility': Icons.visibility_outlined,
  'lock': Icons.lock_outline,
  // — comms / time —
  'email': Icons.email_outlined,
  'notifications': Icons.notifications_outlined,
  'history': Icons.history,
  'event': Icons.event_outlined,
  'alarm': Icons.alarm,
  // — symbols —
  'rocket': Icons.rocket_launch_outlined,
  'lightbulb': Icons.lightbulb_outline,
  'tag': Icons.local_offer_outlined,
  'diamond': Icons.diamond_outlined,
  'public': Icons.public,
  'location': Icons.location_on_outlined,
  'shield': Icons.shield_outlined,
  'timeline': Icons.timeline,
};

/// Default icon for a saved view with no custom selection. Preserved from the
/// feature's original hardcoded look — a bookmark reads as "this is a saved
/// view", not the entity's own nav icon.
const IconData kSavedViewDefaultIcon = Icons.bookmark_outline;

/// Resolve a persisted icon key to its [IconData]. Unknown / null keys fall
/// back to [kSavedViewDefaultIcon], so a removed key never blanks a row.
IconData savedViewIcon(String? key) =>
    kSavedViewIcons[key] ?? kSavedViewDefaultIcon;
