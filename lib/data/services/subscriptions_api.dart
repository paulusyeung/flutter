import 'package:admin/data/models/api/subscription_api_model.dart';
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
    final raw = await client.postJson(
      '$basePath/steps/check',
      body: {'steps': orderedStepIds.join(',')},
      readOnly: true,
    );
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    if (raw is Map) {
      // 422 envelope: `{errors: {steps: ["..."]}}` (React reference,
      // Steps.tsx:77). The string list is nested under `errors.steps`.
      final errors = raw['errors'];
      if (errors is Map && errors['steps'] is List) {
        return (errors['steps'] as List)
            .map((e) => e.toString())
            .toList(growable: false);
      }
      if (errors is List) {
        return errors.map((e) => e.toString()).toList(growable: false);
      }
    }
    return const <String>[];
  }
}
