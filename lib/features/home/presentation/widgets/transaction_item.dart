import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wallet/domain/entities/transaction.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'DELIVERY_INCOME':
        return Icons.arrow_upward;
      case 'WITHDRAWAL':
        return Icons.arrow_downward;
      case 'REFUND':
        return Icons.replay;
      case 'COD_DEBIT':
        return Icons.local_shipping;
      default:
        return Icons.swap_vert;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'DELIVERY_INCOME':
        return AppColors.success;
      case 'WITHDRAWAL':
        return AppColors.errorLight;
      case 'REFUND':
        return AppColors.warning;
      case 'COD_DEBIT':
        return Colors.orange;
      default:
        return AppColors.info;
    }
  }

  String _labelForType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'DELIVERY_INCOME':
        return l10n.earningDelivery;
      case 'WITHDRAWAL':
        return l10n.withdrawal;
      case 'REFUND':
        return l10n.refund;
      case 'COD_DEBIT':
        return l10n.codCollection;
      default:
        return l10n.transaction;
    }
  }

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'PENDING':
        return l10n.pending;
      case 'COMPLETED':
        return l10n.completed;
      case 'FAILED':
        return l10n.failed;
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'COMPLETED':
        return AppColors.success;
      case 'FAILED':
        return AppColors.errorLight;
      default:
        return AppColors.outlineLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _colorForType(transaction.type);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconForType(transaction.type),
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? _labelForType(transaction.type, l10n),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurfaceLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(transaction.createdAt, l10n),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.onBackgroundDark
                            : AppColors.onBackgroundLight,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(transaction.type == 'WITHDRAWAL' || transaction.type == 'COD_DEBIT') ? '-' : '+'}${_formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _statusColor(transaction.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusLabel(transaction.status, l10n),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(transaction.status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDate(DateTime dt, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
