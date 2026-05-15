import 'package:admin/data/models/api/webhook_api_model.dart';
import 'package:admin/data/services/base_entity_api.dart';

/// Concrete API for `/api/v1/webhooks`.
class WebhooksApi extends BaseEntityApi<WebhookListApi, WebhookItemApi> {
  WebhooksApi(super.client);

  @override
  String get basePath => '/api/v1/webhooks';

  @override
  WebhookListApi parseList(Object json) =>
      WebhookListApi.fromJson(json as Map<String, dynamic>);

  @override
  WebhookItemApi parseItem(Object json) =>
      WebhookItemApi.fromJson(json as Map<String, dynamic>);
}
