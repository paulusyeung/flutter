import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// `NativeDatabase.memory()` is itself a `QueryExecutor`; wrapped in a Future
/// to match the web side's async signature.
Future<QueryExecutor> openInMemoryExecutor() async => NativeDatabase.memory();
