import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../bloc/home_event.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedFilter = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<dynamic> _filteredOrders(List<dynamic> orders) {
    switch (_selectedFilter) {
      case 1:
        return orders.where((o) => o.isPickingUp).toList();
      case 2:
        return orders.where((o) => o.isOnTheWay).toList();
      case 3:
        return orders.where((o) => o.isCompleted).toList();
      case 4:
        return orders.where((o) => o.isCancelled).toList();
      default:
        return orders;
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final filtered = _filteredOrders(state.recentOrders);
        final stats = state.todayStats;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(const HomeLoadRequested());
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatsRow(stats, isDark, primaryColor, l10n),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildFilterChips(isDark, primaryColor, l10n),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(isDark, l10n),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final order = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OrderCard(
                              order: order,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<HomeBloc>(),
                                      child: OrderDetailScreen(order: order),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(
    dynamic stats,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.today,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.onBackgroundDark
                          : AppColors.onBackgroundLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 16, color: AppColors.info),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.ordersToday}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.onSurfaceLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.orders,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.onBackgroundDark
                              : AppColors.onBackgroundLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(stats.earningsToday),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalEarned,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.onBackgroundDark
                          : AppColors.onBackgroundLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.route, size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.totalOrders}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.onSurfaceLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.totalTrips,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.onBackgroundDark
                              : AppColors.onBackgroundLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${stats.rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.onSurfaceDark
                              : AppColors.onSurfaceLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(bool isDark, Color primaryColor, AppLocalizations l10n) {
    final filters = [
      l10n.allOrders,
      l10n.pickingUp,
      l10n.delivering,
      l10n.completed,
      l10n.cancelled,
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == index;
          return FilterChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = index),
            selectedColor: primaryColor.withValues(alpha: 0.2),
            checkmarkColor: primaryColor,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? primaryColor
                  : (isDark
                      ? AppColors.onBackgroundDark
                      : AppColors.onBackgroundLight),
            ),
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? primaryColor
                    : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noRecentOrders,
            style: TextStyle(
              fontSize: 16,
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
