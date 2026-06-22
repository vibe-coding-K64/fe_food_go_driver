import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/entities/order.dart';
import 'order_card.dart';

class AvailableOrdersSection extends StatelessWidget {
  final List<Order> availableOrders;
  final VoidCallback onRefresh;
  final VoidCallback? onViewAll;

  const AvailableOrdersSection({
    super.key,
    required this.availableOrders,
    required this.onRefresh,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  l10n.availableOrders,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                  ),
                ),
                const SizedBox(width: 8),
                if (availableOrders.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${availableOrders.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            if (availableOrders.isNotEmpty)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  l10n.viewAll,
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (availableOrders.isEmpty)
          _buildEmptyState(isDark, l10n)
        else
          RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableOrders.length > 5 ? 5 : availableOrders.length,
              itemBuilder: (context, index) {
                return OrderCard(
                  order: availableOrders[index],
                  onTap: onViewAll,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 40,
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noAvailableOrders,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.onBackgroundDark
                  : AppColors.onBackgroundLight,
            ),
          ),
        ],
      ),
    );
  }
}
