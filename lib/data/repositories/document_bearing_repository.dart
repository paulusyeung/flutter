/// Interface every entity repository implements when it supports document
/// attachments. Lets UI helpers (e.g. `buildStandardDocumentsTab`) take a
/// typed repo without knowing the concrete entity type — every doc-bearing
/// repo (Client / Product / Project / Vendor / Expense / RecurringExpense /
/// Invoice) honors this contract, with uniform `entityId:` parameter names.
///
/// Dart's implicit-interface model means the 7 concrete repos already
/// satisfy this — declaring `implements DocumentBearingRepository` on each
/// just adds a static type assertion the compiler can use to enforce the
/// shape stays uniform.
abstract class DocumentBearingRepository {
  Future<void> uploadDocument({
    required String companyId,
    required String entityId,
    required String localPath,
  });

  Future<void> deleteDocument({
    required String companyId,
    required String entityId,
    required String documentId,
  });

  Future<void> setDocumentVisibility({
    required String companyId,
    required String entityId,
    required String documentId,
    required bool isPublic,
  });
}
