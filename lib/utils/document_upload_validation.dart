import 'package:admin/data/services/upload_source.dart';

/// Allowlist of file extensions the server accepts as document attachments
/// (mirrors what admin-portal allows). Sent to the picker as a hard filter,
/// and re-checked after pick/drop because some pickers ignore the filter on
/// certain platforms.
const kDocumentAllowedExtensions = <String>[
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
  'txt',
  'csv',
  'rtf',
  'odt',
  'ods',
  'odp',
  'png',
  'jpg',
  'jpeg',
  'gif',
  'webp',
  'heic',
  'svg',
];

/// Hard cap on uploaded file size. The server enforces this too, but
/// rejecting client-side saves a wasted round-trip and gives the user a
/// crisp message.
const int kDocumentMaxBytes = 25 * 1024 * 1024;

/// Convenience MB constant for display in the "too large" toast.
const int kDocumentMaxMb = kDocumentMaxBytes ~/ (1024 * 1024);

enum DocumentUploadIssue { wrongExtension, tooLarge, unreadable }

/// Result of a pre-upload validation check.
class DocumentUploadValidation {
  const DocumentUploadValidation.ok(this.fileName, this.sizeBytes)
    : issue = null;
  const DocumentUploadValidation.failed(this.fileName, this.issue)
    : sizeBytes = 0;

  final String fileName;
  final int sizeBytes;
  final DocumentUploadIssue? issue;

  bool get isOk => issue == null;
}

/// Validate one [UploadSource] against the allowlist + size cap. Used by
/// `EntityDocumentsTab` for both the file-picker and drag-drop paths (and
/// on every platform) so the reject toasts are identical regardless of how
/// the user added the file. Extension comes from [UploadSource.fileName];
/// size from [UploadSource.length] (cheap on both the file and bytes form).
Future<DocumentUploadValidation> validateDocumentUpload(
  UploadSource source,
) async {
  final name = source.fileName;
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
  if (!kDocumentAllowedExtensions.contains(ext)) {
    return DocumentUploadValidation.failed(
      name,
      DocumentUploadIssue.wrongExtension,
    );
  }
  int size;
  try {
    size = await source.length();
  } catch (_) {
    return DocumentUploadValidation.failed(
      name,
      DocumentUploadIssue.unreadable,
    );
  }
  if (size > kDocumentMaxBytes) {
    return DocumentUploadValidation.failed(name, DocumentUploadIssue.tooLarge);
  }
  return DocumentUploadValidation.ok(name, size);
}
