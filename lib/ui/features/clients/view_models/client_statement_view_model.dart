import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'package:admin/data/models/domain/client.dart';
import 'package:admin/data/models/value/dashboard_filter.dart';
import 'package:admin/data/repositories/client_repository.dart';
import 'package:admin/data/services/api_exception.dart';
import 'package:admin/data/services/clients_api.dart';
import 'package:admin/data/services/connectivity_watcher.dart';

final _log = Logger('ClientStatementViewModel');

/// Status filter for the client statement. Mirrors the values accepted by
/// `POST /api/v1/client_statement#status`. Co-located with the VM because the
/// statement filter is a UI-state concept — the wire layer only sees a
/// `String`.
enum StatementStatus { all, paid, unpaid }

/// Outcome of the most recent statement fetch.
sealed class StatementError {
  const StatementError(this.message);
  final String message;
}

class StatementNetworkError extends StatementError {
  const StatementNetworkError(super.message);
}

class StatementServerError extends StatementError {
  const StatementServerError(super.message, this.statusCode);
  final int statusCode;
}

class StatementValidationError extends StatementError {
  const StatementValidationError(super.message, this.fieldErrors);
  final Map<String, List<String>> fieldErrors;
}

/// State for the read-only Client statement screen.
///
/// The statement is a server-side read disguised as a POST — no outbox row,
/// no idempotency key, no caching. Each filter change re-fetches.
class ClientStatementViewModel extends ChangeNotifier {
  ClientStatementViewModel({
    required this.repo,
    required this.api,
    required this.connectivity,
    required this.companyId,
    required this.clientId,
    int firstMonthOfYear = 1,
  }) : _firstMonthOfYear = firstMonthOfYear {
    _subscribe();
    // Kick a first load as soon as the screen mounts; filter defaults are set
    // already so the request fires without waiting for a user interaction.
    unawaited(load());
  }

  final ClientRepository repo;
  final ClientsApi api;
  final ConnectivityWatcher connectivity;
  final String companyId;
  final String clientId;

  /// Company `first_month_of_year`, used to resolve the `thisYear` / `lastYear`
  /// presets onto the fiscal year — matching the picker preview and the
  /// dashboard. Sourced from the screen's `Formatter`; see
  /// [updateFiscalYearStart].
  int _firstMonthOfYear;

  // ---- filter state ----

  DashboardDateRange _range = const DashboardPresetRange(
    DashboardDatePreset.last365,
  );
  DashboardDateRange get range => _range;

  StatementStatus _status = StatementStatus.all;
  StatementStatus get status => _status;

  bool _showPayments = true;
  bool get showPayments => _showPayments;

  bool _showCredits = false;
  bool get showCredits => _showCredits;

  bool _showAging = false;
  bool get showAging => _showAging;

  // ---- result state ----

  Client? _client;
  Client? get client => _client;

  Uint8List? _pdfBytes;
  Uint8List? get pdfBytes => _pdfBytes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StatementError? _error;
  StatementError? get error => _error;

  // Monotonic request sequence — rapidly toggling filters fires N overlapping
  // loads; whichever resolves last must NOT clobber the bytes from the latest
  // request. Stamp each call, compare on resolve.
  int _reqSeq = 0;

  // Debounce filter changes so a flurry of checkbox toggles fires one load
  // instead of N. 300 ms keeps the UI responsive while letting a confident
  // user finish their pick before we hit the network.
  Timer? _debounce;
  static const _debounceDelay = Duration(milliseconds: 300);

  bool _disposed = false;
  StreamSubscription<Client?>? _clientSub;

  void _subscribe() {
    _clientSub = repo.watch(companyId: companyId, id: clientId).listen((c) {
      if (_disposed) return;
      _client = c;
      notifyListeners();
    });
  }

  void setRange(DashboardDateRange r) {
    if (_disposed || _range == r) return;
    _range = r;
    notifyListeners();
    _scheduleLoad();
  }

  /// Push the company's `first_month_of_year` in once the screen's `Formatter`
  /// resolves. Reloads only when the active range is a fiscal-sensitive preset
  /// (`thisYear` / `lastYear`) so the default rolling ranges don't refetch.
  void updateFiscalYearStart(int firstMonthOfYear) {
    if (_disposed || firstMonthOfYear == _firstMonthOfYear) return;
    final wasFiscalSensitive =
        _range is DashboardPresetRange &&
        ((_range as DashboardPresetRange).preset ==
                DashboardDatePreset.thisYear ||
            (_range as DashboardPresetRange).preset ==
                DashboardDatePreset.lastYear);
    _firstMonthOfYear = firstMonthOfYear;
    if (wasFiscalSensitive) _scheduleLoad();
  }

  void setStatus(StatementStatus s) {
    if (_disposed || _status == s) return;
    _status = s;
    notifyListeners();
    _scheduleLoad();
  }

  void setShowPayments(bool v) {
    if (_disposed || _showPayments == v) return;
    _showPayments = v;
    notifyListeners();
    _scheduleLoad();
  }

  void setShowCredits(bool v) {
    if (_disposed || _showCredits == v) return;
    _showCredits = v;
    notifyListeners();
    _scheduleLoad();
  }

  void setShowAging(bool v) {
    if (_disposed || _showAging == v) return;
    _showAging = v;
    notifyListeners();
    _scheduleLoad();
  }

  void _scheduleLoad() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (_disposed) return;
      unawaited(load());
    });
  }

  /// Fetch the statement with the current filters. Public so the AppBar
  /// refresh and the error-state Retry can call it without going through the
  /// debounce.
  Future<void> load() async {
    if (_disposed) return;
    final seq = ++_reqSeq;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Online gate. Statement generation is server-only; no cached fallback.
    if (!await connectivity.isOnline) {
      if (_disposed || seq != _reqSeq) return;
      _isLoading = false;
      _error = const StatementNetworkError('Offline');
      notifyListeners();
      return;
    }

    final (start, end) = _range.resolve(firstMonthOfYear: _firstMonthOfYear);
    try {
      final bytes = await api.getStatement(
        clientId: clientId,
        startDate: start,
        endDate: end,
        status: _status.name,
        showPayments: _showPayments,
        showCredits: _showCredits,
        showAging: _showAging,
      );
      if (_disposed || seq != _reqSeq) return;
      _pdfBytes = bytes;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } on UnauthorizedException {
      // Bubble: the global 401 single-flight in ApiClient already triggered
      // logout. Don't surface a screen-local error — the router redirect to
      // /login will pull the user off this screen.
      rethrow;
    } on ValidationException catch (e) {
      if (_disposed || seq != _reqSeq) return;
      _isLoading = false;
      _error = StatementValidationError(e.message, e.fieldErrors);
      notifyListeners();
    } on NetworkException catch (e) {
      if (_disposed || seq != _reqSeq) return;
      _isLoading = false;
      _error = StatementNetworkError(e.message);
      notifyListeners();
    } on ServerException catch (e) {
      if (_disposed || seq != _reqSeq) return;
      _isLoading = false;
      _error = StatementServerError(e.message, e.statusCode);
      notifyListeners();
    } catch (e, st) {
      _log.warning('Statement load failed', e, st);
      if (_disposed || seq != _reqSeq) return;
      _isLoading = false;
      _error = StatementServerError(e.toString(), 0);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _clientSub?.cancel();
    super.dispose();
  }
}
