import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin/data/models/api/system_log_api_model.dart';
import 'package:admin/data/models/value/parsing.dart';

part 'system_log.freezed.dart';

/// Tone for the event badge color. The visible label always comes from
/// [SystemLog.eventKey]; the tone is purely a chrome hint.
enum SystemLogTone { success, warning, failure, neutral }

/// Server-side system log row backing Settings → System Logs. Read-only —
/// no outbox / mutation surface.
@freezed
abstract class SystemLog with _$SystemLog {
  const SystemLog._();

  const factory SystemLog({
    required String id,
    required String companyId,
    required String userId,
    required String clientId,
    required int eventId,
    required int categoryId,
    required int typeId,
    required String log,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SystemLog;

  factory SystemLog.fromApi(SystemLogApi a) => SystemLog(
    id: a.id,
    companyId: a.companyId,
    userId: a.userId,
    clientId: a.clientId,
    eventId: a.eventId,
    categoryId: a.categoryId,
    typeId: a.typeId,
    log: a.log,
    createdAt: epochSecondsToUtc(a.createdAt),
    updatedAt: epochSecondsToUtc(a.updatedAt),
  );

  /// Translation key for the category cell. Mirrors React's
  /// `SystemLog.tsx:76-82` mapping.
  String get categoryKey {
    switch (categoryId) {
      case 1:
        return 'gateway_id';
      case 2:
        return 'email';
      case 3:
        return 'webhook';
      case 4:
        return 'pdf';
      case 5:
        return 'security';
      case 6:
        return 'log';
      default:
        return 'unknown';
    }
  }

  /// Translation key for the event badge. Mirrors React's
  /// `SystemLog.tsx:84-101` mapping. Deliberately uses React's `success`
  /// / `failure` / `email_delivery` / `opened` / `login_failure` keys —
  /// v1's `system_log_model.dart` uses different (less translated) keys
  /// like `email_delivered` and `authentication_failure`.
  String get eventKey {
    switch (eventId) {
      case 10:
        return 'payment_failure';
      case 11:
        return 'payment_success';
      case 21:
        return 'success';
      case 22:
        return 'failure';
      case 23:
        return 'error';
      case 30:
        return 'email_send';
      case 31:
        return 'email_retry_queue';
      case 32:
        return 'email_bounced';
      case 33:
        return 'email_spam_complaint';
      case 34:
        return 'email_delivery';
      case 35:
        return 'opened';
      case 40:
        return 'webhook_response';
      case 41:
        return 'webhook_success';
      case 42:
        return 'webhook_failure';
      case 50:
        return 'pdf';
      case 60:
        return 'login_failure';
      case 61:
        return 'user';
      default:
        return 'unknown';
    }
  }

  /// Tone for the event badge color. Tones map to `success/warning/danger
  /// /accentSoft` color tokens in the screen.
  SystemLogTone get tone {
    switch (eventId) {
      case 11:
      case 21:
      case 34:
      case 35:
      case 41:
        return SystemLogTone.success;
      case 10:
      case 22:
      case 32:
      case 33:
      case 42:
      case 60:
        return SystemLogTone.failure;
      case 23:
      case 31:
        return SystemLogTone.warning;
      default:
        return SystemLogTone.neutral;
    }
  }
}

extension SystemLogType on SystemLog {
  /// Display name for the type column. Some ids have translation keys
  /// (returned as `'tr:<key>'` so the UI can `context.tr(...)`); others are
  /// literal vendor names (returned as `'lit:<text>'`). React keeps both
  /// forms inline (`SystemLog.tsx:103-130`) — encoding here keeps the
  /// branching out of the widget.
  ({bool isKey, String value}) typeDisplay() {
    switch (typeId) {
      case 300:
        return (isKey: true, value: 'paypal');
      case 301:
        return (isKey: true, value: 'payment_type_stripe');
      case 302:
        return (isKey: true, value: 'ledger');
      case 303:
        return (isKey: true, value: 'failure');
      case 304:
        return (isKey: true, value: 'checkout_com');
      case 305:
        return (isKey: false, value: 'auth.net');
      case 306:
        return (isKey: true, value: 'custom');
      case 307:
        return (isKey: false, value: 'Braintree');
      case 309:
        return (isKey: true, value: 'wepay');
      case 310:
        return (isKey: false, value: 'PayFast');
      case 311:
        return (isKey: false, value: 'PayTrace');
      case 312:
        return (isKey: false, value: 'Mollie');
      case 313:
        return (isKey: false, value: 'eWay');
      case 314:
        return (isKey: false, value: 'Forte');
      case 320:
        return (isKey: false, value: 'Square');
      case 321:
        return (isKey: true, value: 'gocardless');
      case 322:
        return (isKey: false, value: 'Razorpay');
      case 323:
        return (isKey: true, value: 'paypal');
      case 400:
        return (isKey: false, value: 'Quota exceeded');
      case 401:
        return (isKey: false, value: 'Upstream failure');
      case 500:
        return (isKey: false, value: 'Webhook response');
      case 600:
        return (isKey: false, value: 'PDF Failure');
      case 601:
        return (isKey: false, value: 'PDF Success');
      case 701:
        return (isKey: false, value: 'Modified');
      case 702:
        return (isKey: false, value: 'Deleted');
      case 800:
        return (isKey: false, value: 'Login Success');
      case 801:
        return (isKey: false, value: 'Login Failure');
      default:
        return (isKey: false, value: 'Undefined Type');
    }
  }
}
