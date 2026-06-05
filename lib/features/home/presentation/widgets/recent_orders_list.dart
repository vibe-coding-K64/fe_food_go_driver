import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/entities/order.dart';
import 'order_card.dart';

class RecentOrdersList extends StatefulWidget {
  final List<Order> orders;
  final Future<void> Function() onRefresh;

  const RecentOrdersList({
    super.key,
    required this.orders,
    required this.onRefresh,
  });

  @override
  State<RecentOrdersList> createState() => _RecentOrdersListState();
}

class _RecentOrdersListState extends State<RecentOrdersList> {
  int _selectedFilter = 0;

  final List<String> _filters = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _filters.clear();
    _filters.addAll([
      l10n.allOrders,
      l10n.pickingUp,
      l10n.delivering,
      l10n.delivered,
      l10n.cancelled,
    ]);
  }

  List<Order> _filteredOrders() {
    switch (_selectedFilter) {
      case 1:
        return widget.orders.where((o) => o.isPickingUp).toList();
      case 2:
        return widget.orders.where((o) => o.isOnTheWay).toList();
      case 3:
        return widget.orders.where((o) => o.isCompleted).toList();
      case 4:
        return widget.orders.where((o) => o.isCancelled).toList();
      default:
        return widget.orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final filtered = _filteredOrders();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.recentOrders,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
            if (widget.orders.isNotEmpty)
              TextButton(
                onPressed: () {},
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
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final isSelected = _selectedFilter == index;
              return FilterChip(
                label: Text(_filters[index]),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = index);
                },
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primaryColor : (isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight),
                ),
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? primaryColor : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: filtered.isEmpty
              ? _buildEmptyState(isDark, l10n)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return OrderCard(
                      order: filtered[index],
                      onTap: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Container(
      height: 120,
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
            l10n.noRecentOrders,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
            ),
          ),
        ],
      ),
    );
  }
}
