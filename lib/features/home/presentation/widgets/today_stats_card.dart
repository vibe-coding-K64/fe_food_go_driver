import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/home_repository_impl.dart';

class TodayStatsCard extends StatelessWidget {
  final TodayStats stats;

  const TodayStatsCard({super.key, required this.stats});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.todayStats,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.receipt_long,
                    stats.ordersToday.toString(),
                    l10n.totalOrders,
                    AppColors.info,
                    isDark,
                  ),
                ),
                Container(width: 1, height: 50, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.monetization_on,
                    _formatCurrency(stats.earningsToday),
                    l10n.earningsToday,
                    AppColors.success,
                    isDark,
                  ),
                ),
                Container(width: 1, height: 50, color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.account_balance_wallet,
                    _formatCurrency(stats.balance),
                    l10n.walletBalance,
                    primaryColor,
                    isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color iconColor,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}
