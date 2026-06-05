/// Maps a bare email-template id — the canonical key shared by the email
/// composer, the Settings → Templates & Reminders editor, and the live
/// preview (`invoice`, `quote`, `quote_reminder1`, `custom2`, …) — to the
/// `CompanySettings` wire property the server expects.
///
/// Every id follows `email_template_<id>` / `email_subject_<id>` **except**
/// `quote_reminder1`, whose server property carries a `quote_` infix
/// (`email_quote_template_reminder1` / `email_quote_subject_reminder1`).
/// That single irregular key was the source of a launch-blocking quote-email
/// send bug: the send path hand-rolled the prefix and missed the exception
/// while the preview/settings copies handled it. Route every producer of
/// these wire names through here so the three can never drift apart again.
///
/// Verified against the server whitelist (`SendEmailRequest::$templates`) and
/// `CompanySettings` (`email_quote_template_reminder1`, line 521).
library;

/// Body/template settings key (e.g. `email_template_invoice`,
/// `email_quote_template_reminder1`).
String emailTemplateWireName(String id) => id == 'quote_reminder1'
    ? 'email_quote_template_reminder1'
    : 'email_template_$id';

/// Subject settings key (e.g. `email_subject_invoice`,
/// `email_quote_subject_reminder1`).
String emailSubjectWireName(String id) => id == 'quote_reminder1'
    ? 'email_quote_subject_reminder1'
    : 'email_subject_$id';
