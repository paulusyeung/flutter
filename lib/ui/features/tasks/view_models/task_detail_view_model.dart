import 'package:admin/data/models/domain/task.dart';
import 'package:admin/ui/core/detail/generic_detail_view_model.dart';

/// Tasks have no screen-specific derived state today (header / cards read
/// off `Task.isInvoiced` / `Task.isRunning` / `Task.totalDuration()`
/// directly). When the time comes to add e.g. a per-task activity log,
/// promote this typedef to a real subclass — same pattern as
/// `ClientDetailViewModel`.
typedef TaskDetailViewModel = GenericDetailViewModel<Task>;
