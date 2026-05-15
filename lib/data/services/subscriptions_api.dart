import 'package:admin/data/models/api/subscription_api_model.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/subscriptions`. Standard CRUD via the base
/// class, plus two helpers for the Steps tab:
///
/// - [listSteps]: the available step catalog + each step's `dependencies`.
///   The wire returns a keyed object (`Record<string, {id,label,deps}>`);
///   we flatten via `.values`.
/// - [checkSteps]: server-side validation of a step ordering. Body is a
///   comma-joined string, mirroring the React client. Returns the
///   validation error strings (`['Cart step requires auth step earlier']`).
///
/// The Steps tab uses client-side dependency checking as the primary
/// surface (see [SubscriptionRepository.checkSteps] for the rationale);
/// this round-trip is a safety net for server-only rules.
class SubscriptionsApi
    extends BaseEntityApi<SubscriptionListApi, SubscriptionItemApi> {
  SubscriptionsApi(super.client);

  @override
  String get basePath => '/api/v1/subscriptions';

  @override
  SubscriptionListApi parseList(Object json) =>
      SubscriptionListApi.fromJson(json as Map<String, dynamic>);

  @override
  SubscriptionItemApi parseItem(Object json) =>
      SubscriptionItemApi.fromJson(json as Map<String, dynamic>);

  Future<List<SubscriptionStepApi>> listSteps() async {
    final raw = await client.getOne('$basePath/steps');
    if (raw is! Map) return const <SubscriptionStepApi>[];
    return raw.values
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionStepApi.fromJson)
        .toList(growable: false);
  }

  Future<List<String>> checkSteps(List<String> orderedStepIds) async {
    if (orderedStepIds.isEmpty) return const <String>[];
    // The server returns 422 with a `{errors: {steps: [...]}}` envelope
    // when validation fails (matches React Steps.tsx:76-78); ApiClient
    // maps that to [ValidationException] with `fieldErrors` keyed by
    // field name. A 200 response means the ordering is valid.
    try {
      await client.postJson(
        '$basePath/steps/check',
        body: {'steps': orderedStepIds.join(',')},
        readOnly: true,
      );
      return const <String>[];
    } on ValidationException catch (e) {
      return e.fieldErrors['steps'] ?? const <String>[];
    }
  }
}
