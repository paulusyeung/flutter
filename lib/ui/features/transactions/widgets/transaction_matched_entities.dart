import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:admin/app/design_tokens.dart';
import 'package:admin/app/router.dart';
import 'package:admin/app/services.dart';
import 'package:admin/data/models/domain/bank_transaction.dart';
import 'package:admin/l10n/localization.dart';
import 'package:admin/ui/core/widgets/link_text.dart';

/// Renders the matched/converted-state chips for a bank transaction:
/// invoice numbers, payment number, vendor + expense category, expense
/// numbers — each as a `LinkText` that routes to the underlying detail
/// screen. Falls back to the raw id text when the entity isn't in the
/// local Drift cache (e.g. archived rows or paged-out entries).
///
/// Used in place of the match panel once `statusId == kTransactionStatusConverted`
/// (and optionally above the panel for `Matched` rows, to show what's
/// already linked).
class TransactionMatchedEntities extends StatelessWidget {
  const TransactionMatchedEntities({super.key, required this.transaction});

  final BankTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    final services = context.read<Services>();
    final companyId = services.auth.session.value?.currentCompanyId ?? '';
    final tx = transaction;

    final children = <Widget>[];

    // CREDIT side — linked invoices + payment.
    if (tx.isDeposit) {
      for (final id in tx.linkedInvoiceIds) {
        children.add(
          _InvoiceChip(id: id, companyId: companyId, services: services),
        );
      }
      if (tx.paymentId.isNotEmpty) {
        // No PaymentRepository in this rebuild yet — render as a tooltip
        // chip that doesn't pretend to be navigable.
        children.add(
          Tooltip(
            message: context.tr('coming_soon'),
            child: _ReadOnlyChip(
              icon: Icons.receipt_outlined,
              label: '${context.tr('payment')}: ${tx.paymentId}',
            ),
          ),
        );
      }
    }

    // DEBIT side — linked vendor + category + expenses.
    if (tx.isWithdrawal) {
      if (tx.vendorId.isNotEmpty) {
        children.add(
          _VendorChip(
            id: tx.vendorId,
            companyId: companyId,
            services: services,
          ),
        );
      }
      if (tx.categoryId.isNotEmpty) {
        children.add(
          _CategoryChip(
            id: tx.categoryId,
            companyId: companyId,
            services: services,
          ),
        );
      }
      for (final id in tx.linkedExpenseIds) {
        children.add(
          _ExpenseChip(id: id, companyId: companyId, services: services),
        );
      }
    }

    if (children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          context.tr('no_matched_entities'),
          style: TextStyle(color: tokens.ink3),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _InvoiceChip extends StatelessWidget {
  const _InvoiceChip({
    required this.id,
    required this.companyId,
    required this.services,
  });
  final String id;
  final String companyId;
  final Services services;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: services.invoices.watch(companyId: companyId, id: id),
      builder: (context, snapshot) {
        final invoice = snapshot.data;
        final label = invoice?.number.isNotEmpty == true
            ? '#${invoice!.number}'
            : '#$id';
        return _NavChip(
          icon: Icons.description_outlined,
          label: label,
          onTap: () => goEntityFullDetail(context, '/invoices', id),
        );
      },
    );
  }
}

class _VendorChip extends StatelessWidget {
  const _VendorChip({
    required this.id,
    required this.companyId,
    required this.services,
  });
  final String id;
  final String companyId;
  final Services services;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: services.vendors.watch(companyId: companyId, id: id),
      builder: (context, snapshot) {
        final vendor = snapshot.data;
        final label = vendor?.name.isNotEmpty == true
            ? vendor!.name
            : context.tr('vendor');
        return _NavChip(
          icon: Icons.store_outlined,
          label: label,
          onTap: () => goEntityFullDetail(context, '/vendors', id),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.id,
    required this.companyId,
    required this.services,
  });
  final String id;
  final String companyId;
  final Services services;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: services.expenseCategories.watch(companyId: companyId, id: id),
      builder: (context, snapshot) {
        final cat = snapshot.data;
        final label = cat?.name.isNotEmpty == true
            ? cat!.name
            : context.tr('category');
        return _NavChip(
          icon: Icons.label_outline,
          label: label,
          onTap: () =>
              goEntityFullDetail(context, '/settings/expense_categories', id),
        );
      },
    );
  }
}

class _ExpenseChip extends StatelessWidget {
  const _ExpenseChip({
    required this.id,
    required this.companyId,
    required this.services,
  });
  final String id;
  final String companyId;
  final Services services;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: services.expenses.watch(companyId: companyId, id: id),
      builder: (context, snapshot) {
        final expense = snapshot.data;
        final label = expense?.number.isNotEmpty == true
            ? '#${expense!.number}'
            : '#$id';
        return _NavChip(
          icon: Icons.account_balance_wallet_outlined,
          label: label,
          onTap: () => goEntityFullDetail(context, '/expenses', id),
        );
      },
    );
  }
}

class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(InRadii.r2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tokens.accentSoft,
          borderRadius: BorderRadius.circular(InRadii.r2),
          border: Border.all(color: tokens.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tokens.accent),
            const SizedBox(width: 6),
            LinkText(
              label: label,
              onTap: onTap,
              style: TextStyle(
                fontSize: 13,
                color: tokens.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  const _ReadOnlyChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.inTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(InRadii.r2),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tokens.ink2),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: tokens.ink2)),
        ],
      ),
    );
  }
}
