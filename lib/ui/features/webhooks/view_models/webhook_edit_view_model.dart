import 'package:admin/data/models/domain/webhook.dart';
import 'package:admin/data/repositories/webhook_repository.dart';
import 'package:admin/ui/core/edit/generic_edit_view_model.dart';

/// Drives the webhook edit/create screen.
class WebhookEditViewModel extends GenericEditViewModel<Webhook> {
  WebhookEditViewModel({
    required this.repo,
    required this.companyId,
    Webhook? existing,
  }) : super(initialDraft: existing ?? _emptyWebhook(), original: existing);

  final WebhookRepository repo;
  final String companyId;

  @override
  bool draftIsNonEmpty() =>
      draft.targetUrl.isNotEmpty || draft.eventId.isNotEmpty;

  @override
  Future<Webhook> performSave() async {
    if (isCreate) {
      return await repo.create(companyId: companyId, draft: draft);
    }
    await repo.save(companyId: companyId, webhook: draft);
    return draft;
  }

  void setTargetUrl(String v) => updateDraft(draft.copyWith(targetUrl: v));
  void setEventId(String v) => updateDraft(draft.copyWith(eventId: v));
  void setRestMethod(String v) => updateDraft(draft.copyWith(restMethod: v));

  void addHeader(String key, String value) {
    if (key.trim().isEmpty) return;
    updateDraft(draft.copyWith(headers: {...draft.headers, key: value}));
  }

  void removeHeader(String key) {
    final next = Map<String, String>.from(draft.headers)..remove(key);
    updateDraft(draft.copyWith(headers: next));
  }
}

Webhook _emptyWebhook() => Webhook(
  id: '',
  eventId: '',
  targetUrl: '',
  format: kWebhookDefaultFormat,
  restMethod: kWebhookDefaultRestMethod,
  isDeleted: false,
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  archivedAt: null,
);
