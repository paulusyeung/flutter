import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/services.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/form_save_scope.dart';
import 'package:admin/ui/core/widgets/notify.dart';
import 'package:admin/ui/core/widgets/searchable_dropdown_field.dart';
import 'package:admin/ui/features/settings/view_models/settings_draft_view_model.dart';
import 'package:admin/ui/features/settings/views/advanced/e_invoice/e_invoice_constants.dart';
import 'package:admin/ui/features/settings/widgets/form_section.dart';

/// Settings → E-Invoice — Payment Means card. Company-scope only.
///
/// `kPaymentMeansCodes` carries 97 UN/CEFACT codes; each code maps to a
/// list of sub-fields via `kPaymentMeansFormElements`. The dropdown picks
/// the code; the body re-renders only the sub-fields the picked code
/// requires. A card-local Save button POSTs to `/einvoice/configurations`
/// through the outbox.
///
/// **MVP limitation:** initial values aren't seeded from the company
/// envelope. The React app reads them off
/// `company.e_invoice.Invoice.PaymentMeans[0]`, which our typed `Company`
/// doesn't carry yet. A follow-up can either parse that blob into
/// `Company.eInvoice` (a `Map<String, dynamic>?` like Invoice already
/// carries) or add a dedicated `GET /einvoice/configurations` endpoint.
/// Users currently re-enter the values whenever they reopen the screen.
class PaymentMeansCard extends StatefulWidget {
  const PaymentMeansCard({super.key});

  @override
  State<PaymentMeansCard> createState() => _PaymentMeansCardState();
}

class _PaymentMeansCardState extends State<PaymentMeansCard> {
  static const _kDefaultCode = '1'; // "Instrument not defined"

  String _code = _kDefaultCode;
  bool _saving = false;
  bool _seeded = false;

  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String field) {
    return _controllers.putIfAbsent(field, TextEditingController.new);
  }

  /// Seed `_code` and the sub-field controllers from the server's saved
  /// config (`company.e_invoice.Invoice.PaymentMeans[0]`) on first build with
  /// a non-null blob. Latched so a later rebuild never clobbers user edits —
  /// without this the card always opened at code '1' and a blind Save wiped
  /// the stored config.
  void _seedIfNeeded(Map<String, dynamic>? eInvoice) {
    if (_seeded || eInvoice == null) return;
    _seeded = true;
    final seed = paymentMeansSeedFromEInvoice(eInvoice);
    if (seed.code != null) _code = seed.code!;
    seed.fields.forEach((field, value) => _controllerFor(field).text = value);
  }

  @override
  Widget build(BuildContext context) {
    _seedIfNeeded(context.watch<SettingsDraftHost>().draft?.eInvoice);
    final fields = kPaymentMeansFormElements[_code] ?? const <String>[];
    final codes = kPaymentMeansCodes.entries.toList()
      ..sort((a, b) {
        // Numeric ids first (sorted numerically), then 'ZZZ' at the end —
        // matches admin-portal's autocomplete ordering.
        final aNum = int.tryParse(a.key);
        final bNum = int.tryParse(b.key);
        if (aNum != null && bNum != null) return aNum.compareTo(bNum);
        if (aNum == null) return 1;
        if (bNum == null) return -1;
        return 0;
      });

    return FormSection(
      title: context.tr('payment_means'),
      trailing: FilledButton(
        // Distinct label from the surrounding page Save button so the user
        // can tell which scope each button writes to (the page Save covers
        // cascade fields; this one writes the payment-means config).
        style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
        onPressed: _saving ? null : _onSave,
        child: _saving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(context.tr('save_payment_means')),
      ),
      children: [
        SearchableDropdownField<MapEntry<String, String>>(
          label: context.tr('code'),
          items: codes,
          initialValue: codes.firstWhere(
            (e) => e.key == _code,
            orElse: () => codes.first,
          ),
          displayString: (e) => '${e.key} — ${e.value}',
          idOf: (e) => e.key,
          onChanged: (e) => setState(() => _code = e?.key ?? _kDefaultCode),
        ),
        for (final field in fields)
          _SubField(field: field, controller: _controllerFor(field)),
      ],
    );
  }

  Future<void> _onSave() async {
    final services = context.read<Services>();
    final host = context.read<SettingsDraftHost>();
    final companyId = host.draft?.id;
    if (companyId == null) return;

    final entry = <String, dynamic>{'code': _code};
    for (final field in kPaymentMeansFormElements[_code] ?? const <String>[]) {
      final value = _controllers[field]?.text.trim() ?? '';
      if (value.isNotEmpty) entry[field] = value;
    }
    final payload = <String, dynamic>{
      'entity': 'company',
      'payment_means': [entry],
    };

    setState(() => _saving = true);
    try {
      await services.company.enqueueEInvoicePaymentMeans(
        companyId: companyId,
        payload: payload,
      );
      if (!mounted) return;
      Notify.success(context, context.tr('saved'));
    } catch (e) {
      if (!mounted) return;
      Notify.error(context, context.tr('could_not_save'), error: e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SubField extends StatelessWidget {
  const _SubField({required this.field, required this.controller});

  /// Wire-name of the sub-field (`iban`, `bic_swift`, `account_holder`, …).
  final String field;
  final TextEditingController controller;

  static const Map<String, String> _kLabelKey = {
    'iban': 'iban',
    'bic_swift': 'bic',
    'payer_bank_account': 'payer_bank_account',
    'account_holder': 'account_holder',
    'bsb_sort': 'bsb_sort',
    'card_type': 'card_type',
    'card_number': 'card_number',
    'card_holder': 'card_holder',
  };

  @override
  Widget build(BuildContext context) {
    final scope = FormSaveScope.maybeOf(context);
    final labelKey = _kLabelKey[field] ?? field;
    final helperKey = _helperKey(field);
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: context.tr(labelKey),
        helperText: helperKey == null ? null : context.tr(helperKey),
      ),
      onSubmitted: scope == null ? null : (_) => scope.trySubmit(),
    );
  }

  /// Maps a sub-field to its `<field>_help` localization key. Returns null
  /// when the key isn't in the bundle — context.tr would render the raw
  /// key, which is uglier than no helper at all.
  String? _helperKey(String field) {
    const withHelp = {
      'iban': 'iban_help',
      'bic_swift': 'bic_swift_help',
      'payer_bank_account': 'payer_bank_account_help',
      'account_holder': 'account_holder_help',
      'bsb_sort': 'bsb_sort_help',
      'card_type': 'card_type_help',
      'card_number': 'card_number_help',
      'card_holder': 'card_holder_help',
    };
    return withHelp[field];
  }
}

/// Flat sub-field → nested path inside a `PaymentMeans[0]` entry, mirroring
/// React's `PaymentMeans.tsx` read paths. The server writes a flat
/// `{code, iban, …}` body but returns this nested UBL shape, so seeding reads
/// from here while the card's Save still POSTs the flat form.
const Map<String, List<String>> _kPaymentMeansSubFieldPaths = {
  'iban': ['PayeeFinancialAccount', 'ID', 'value'],
  'bic_swift': [
    'PayeeFinancialAccount',
    'FinancialInstitutionBranch',
    'FinancialInstitution',
    'ID',
    'value',
  ],
  'account_holder': ['PayeeFinancialAccount', 'Name'],
  'payer_bank_account': ['PayerFinancialAccount', 'ID', 'value'],
  'bsb_sort': ['PayeeFinancialAccount', 'SortCode', 'value'],
  'card_type': ['CardAccount', 'NetworkID', 'value'],
  'card_number': ['CardAccount', 'PrimaryAccountNumberID', 'value'],
  'card_holder': ['CardAccount', 'HolderName', 'value'],
};

/// Pure extraction of the Payment Means seed from a company `e_invoice` blob
/// (the nested UBL shape the server returns). Walks `Invoice.PaymentMeans[0]`
/// and returns the payment-means code (or null) plus the flat sub-field values
/// present. Safe on null / non-map / missing hops — returns an empty result
/// rather than throwing. Public + pure so the path strings are unit-testable
/// without widget scaffolding (mirrors `buildPeppolSetupPayload`).
({String? code, Map<String, String> fields}) paymentMeansSeedFromEInvoice(
  Map<String, dynamic>? eInvoice,
) {
  final pm = _node(eInvoice, const ['Invoice', 'PaymentMeans', 0]);
  if (pm is! Map) return (code: null, fields: const <String, String>{});
  final rawCode = _str(_node(pm, const ['PaymentMeansCode', 'value']));
  final fields = <String, String>{};
  _kPaymentMeansSubFieldPaths.forEach((field, path) {
    final value = _str(_node(pm, path));
    if (value != null && value.isNotEmpty) fields[field] = value;
  });
  return (
    code: (rawCode != null && rawCode.isNotEmpty) ? rawCode : null,
    fields: fields,
  );
}

/// Walk a path of map keys + list indices into the nested `e_invoice` blob.
/// Returns the node at the path, or null on any missing/wrong-typed hop.
Object? _node(Object? root, List<Object> path) {
  Object? cur = root;
  for (final key in path) {
    if (cur is Map && key is String) {
      cur = cur[key];
    } else if (cur is List && key is int && key >= 0 && key < cur.length) {
      cur = cur[key];
    } else {
      return null;
    }
  }
  return cur;
}

/// Coerce a leaf node to a display string (the server ships values as either
/// a bare string or a number).
String? _str(Object? node) {
  if (node is String) return node;
  if (node is num) return node.toString();
  return null;
}
