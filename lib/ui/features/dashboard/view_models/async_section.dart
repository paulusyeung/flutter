/// Sum-type for the lifecycle of a single dashboard card's data.
///
/// `idle` — no fetch attempted yet (cold start).
/// `loading` — first fetch in flight; `data` may be `null` (no cache hit) or
///   stale (previous fetch's value, kept so the UI doesn't flash empty).
/// `ready` — last fetch succeeded; `data` holds the canonical value.
/// `error` — last fetch failed; `data` may still hold a prior value.
class AsyncSection<T> {
  const AsyncSection._({required this.status, this.data, this.error});

  const AsyncSection.idle() : this._(status: AsyncStatus.idle);
  const AsyncSection.loading({T? data})
    : this._(status: AsyncStatus.loading, data: data);
  const AsyncSection.ready(T data)
    : this._(status: AsyncStatus.ready, data: data);
  const AsyncSection.error(Object error, {T? data})
    : this._(status: AsyncStatus.error, data: data, error: error);

  final AsyncStatus status;
  final T? data;
  final Object? error;

  bool get isLoading => status == AsyncStatus.loading;
  bool get hasError => status == AsyncStatus.error;
  bool get hasData => data != null;

  AsyncSection<T> withData(T? next) {
    if (next == null) {
      return AsyncSection<T>._(status: status, error: error);
    }
    return AsyncSection<T>._(status: AsyncStatus.ready, data: next);
  }
}

enum AsyncStatus { idle, loading, ready, error }
