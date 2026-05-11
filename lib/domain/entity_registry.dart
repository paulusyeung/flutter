import 'package:flutter/material.dart' show IconData, Icons;

import 'entity_type.dart';
import 'sync/mutation.dart';
import 'sync/sync_dispatcher.dart';

/// Per-entity metadata + the sync dispatcher that knows how to talk to the
/// server for this entity. The sync engine, outbox screen, permissions
/// checks, and shell navigation all read from here so adding a new entity
/// is mechanical.
class EntityHandlers {
  const EntityHandlers({
    required this.type,
    required this.wireName,
    required this.apiPath,
    required this.routePath,
    required this.icon,
    required this.dispatcher,
    this.parent,
    this.children = const [],
    this.requiresPasswordFor = const {},
  });

  final EntityType type;

  /// Stored in `outbox.entity_type`; sent in some API filter params; never
  /// changed once an entity ships (rename would break existing outbox rows).
  final String wireName;

  /// Server collection path, e.g. `/api/v1/clients`.
  final String apiPath;

  /// Top-level UI route, e.g. `/clients`.
  final String routePath;

  final IconData icon;
  final EntityType? parent;
  final List<EntityType> children;
  final Set<MutationKind> requiresPasswordFor;
  final SyncDispatcher dispatcher;
}

/// In-memory map populated at app start (DI). The map drives the entire
/// per-entity machinery — sync engine, outbox screen, etc.
class EntityRegistry {
  EntityRegistry(this._byType)
    : _byWire = {for (final h in _byType.values) h.wireName: h};

  final Map<EntityType, EntityHandlers> _byType;
  final Map<String, EntityHandlers> _byWire;

  EntityHandlers? operator [](EntityType type) => _byType[type];
  EntityHandlers? byWireName(String wireName) => _byWire[wireName];

  Iterable<EntityHandlers> get all => _byType.values;
}

/// Default-icon helper for entity types we don't have art for yet.
IconData iconFor(EntityType t) => switch (t) {
  EntityType.client => Icons.people,
  EntityType.invoice => Icons.receipt_long,
  EntityType.quote => Icons.request_quote,
  EntityType.payment => Icons.payments,
  EntityType.product => Icons.inventory_2,
  _ => Icons.folder,
};
