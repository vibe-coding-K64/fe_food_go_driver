import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../pages/available_orders_screen.dart';

class AvailableOrderCard extends StatelessWidget {
  final AvailableOrder order;
  final String Function(double) formatCurrency;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const AvailableOrderCard({
    super.key,
    required this.order,
    required this.formatCurrency,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStoreInfo(isDark),
            const Divider(height: 24),
            _buildDeliveryInfo(isDark),
            const SizedBox(height: 12),
            _buildItemsPreview(isDark),
            const SizedBox(height: 12),
            _buildPriceSection(isDark),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.store, color: AppColors.primaryLight, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.storeName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (order.storeAddress != null)
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.outlineLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.storeAddress!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.onBackgroundDark
                              : AppColors.onBackgroundLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryInfo(bool isDark) {
    return Row(
      children: [
        const Icon(Icons.delivery_dining,
            size: 20, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            order.deliveryAddress,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsPreview(bool isDark) {
    final displayItems = order.items.take(2).toList();
    final extraCount = order.items.length - 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}x',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.onSurfaceDark
                            : AppColors.onSurfaceLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formatCurrency(item.price * item.quantity),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.onBackgroundDark
                          : AppColors.onBackgroundLight,
                    ),
                  ),
                ],
              ),
            )),
        if (extraCount > 0)
          Text(
            '+ $extraCount more items',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildPriceSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng đơn',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
            Text(
              '${formatCurrency(order.totalAmount)} VND',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Tiền cước',
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
            Text(
              '${formatCurrency(order.deliveryFee)} VND',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: onDecline,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorLight,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Từ chối'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Nhận đơn',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
