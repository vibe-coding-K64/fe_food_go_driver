import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/entities/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  Color _statusColor(int status, bool isDark) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return AppColors.info;
      case 2:
        return AppColors.busy;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.errorLight;
      default:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
  }

  String _statusText(int status, AppLocalizations l10n) {
    switch (status) {
      case 0:
        return l10n.status;
      case 1:
        return l10n.pickup;
      case 2:
        return l10n.delivering;
      case 3:
        return l10n.delivered;
      case 4:
        return l10n.cancelled;
      default:
        return l10n.status;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Vua xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phut truoc';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} gio truoc';
    } else {
      return DateFormat('dd/MM HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final statusColor = _statusColor(order.status, isDark);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (order.code != null && order.code!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.code!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.store, size: 14, color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          order.storeName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusText(order.status, l10n),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.deliveryAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(order.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_formatCurrency(order.deliveryFee)} VND',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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
}
