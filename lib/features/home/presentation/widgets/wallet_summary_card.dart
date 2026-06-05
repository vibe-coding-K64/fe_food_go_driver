import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wallet/domain/entities/wallet.dart';

class WalletSummaryCard extends StatelessWidget {
  final Wallet? wallet;
  final VoidCallback onWithdraw;
  final VoidCallback onTransactionHistory;

  const WalletSummaryCard({
    super.key,
    this.wallet,
    required this.onWithdraw,
    required this.onTransactionHistory,
  });

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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.primaryDark.withValues(alpha: 0.15),
                    AppColors.primaryContainerDark.withValues(alpha: 0.3),
                  ]
                : [
                    AppColors.primaryLight.withValues(alpha: 0.1),
                    AppColors.primaryContainerLight.withValues(alpha: 0.3),
                  ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.wallet,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                    ),
                  ),
                  Icon(Icons.account_balance_wallet, color: primaryColor, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                wallet != null ? '${_formatCurrency(wallet!.balance)} VND' : '0 VND',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.balanceAvailable,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      context,
                      Icons.trending_up,
                      wallet != null ? _formatCurrency(wallet!.totalEarned) : '0',
                      l10n.totalEarned,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMiniStat(
                      context,
                      Icons.hourglass_empty,
                      wallet != null ? _formatCurrency(wallet!.pendingBalance) : '0',
                      l10n.pendingBalance,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onWithdraw,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(l10n.withdraw),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: onTransactionHistory,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(l10n.transactionHistory),
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

  Widget _buildMiniStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
