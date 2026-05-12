import 'package:admin/data/models/domain/client.dart';
import 'package:admin/ui/core/list/entity_list_column_headers.dart';

// The generic widget lives in `lib/ui/core/list/entity_list_column_headers.dart`.
// Keep this typedef so existing imports stay quiet — products and any future
// entity can use [EntityListColumnHeaders] directly.
typedef ClientListColumnHeaders = EntityListColumnHeaders<Client>;
