import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

  String _labelForType(String type) {
    switch (type) {
      case 'DELIVERY_INCOME':
        return 'Thu nhập giao hàng';
      case 'WITHDRAWAL':
        return 'Rút tiền';
      case 'REFUND':
        return 'Hoàn tiền';
      case 'COD_DEBIT':
        return 'Thu COD';
      default:
        return 'Giao dịch';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Đang chờ';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'FAILED':
        return 'Thất bại';
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
                      transaction.description ?? _labelForType(transaction.type),
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
                      _formatDate(transaction.createdAt),
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
                      _statusLabel(transaction.status),
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

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
