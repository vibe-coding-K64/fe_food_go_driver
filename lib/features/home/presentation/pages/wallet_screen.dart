import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_event.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';
import '../../../wallet/domain/entities/transaction.dart';
import '../widgets/transaction_item.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WalletBloc(walletRepository: GetIt.instance<WalletRepository>())
            ..add(const LoadWalletTransactionsOnly()),
      child: const _WalletScreenContent(),
    );
  }
}

class _WalletScreenContent extends StatefulWidget {
  const _WalletScreenContent();

  @override
  State<_WalletScreenContent> createState() => _WalletScreenContentState();
}

class _WalletScreenContentState extends State<_WalletScreenContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _filters = ['all', 'earning', 'withdrawal', 'refund'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final filter = _filters[_tabController.index];
      context.read<WalletBloc>().add(FilterTransactions(filter));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state.withdrawStatus == WithdrawStatus.success) {
          _showSuccessDialog(context, l10n, state.wallet?.balance ?? 0);
        }
        if (state.withdrawErrorMessage != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorLight, size: 24),
                  SizedBox(width: 8),
                  Text(l10n.notifications),
                ],
              ),
              content: Text(state.withdrawErrorMessage!),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorLight,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.close),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(
                    LoadWalletTransactionsOnly(filter: state.transactionFilter),
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildBalanceCard(context, state, isDark, primaryColor, l10n),
                  _buildStatsRow(context, state, isDark, primaryColor, l10n),
                  _buildBankInfo(context, state, isDark, primaryColor, l10n),
                  _buildTransactionSection(
                      context, state, isDark, primaryColor, l10n),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    WalletState state,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primaryDark.withValues(alpha: 0.3),
                  AppColors.primaryContainerDark.withValues(alpha: 0.5),
                ]
              : [
                  AppColors.primaryLight.withValues(alpha: 0.2),
                  AppColors.primaryContainerLight.withValues(alpha: 0.5),
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.balanceAvailable,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.wallet != null
                ? '${_formatCurrency(state.wallet!.balance)} VND'
                : '0 VND',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  state.wallet != null && state.wallet!.balance >= 50000
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<WalletBloc>(),
                                child: WithdrawScreen(
                                    balance: state.wallet!.balance),
                              ),
                            ),
                          );
                        }
                      : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.withdraw),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    WalletState state,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              Icons.trending_up,
              state.wallet != null
                  ? _formatCurrency(state.wallet!.totalEarned)
                  : '0',
              l10n.totalEarned,
              AppColors.success,
              isDark,
            ),
          ),
          Container(
              width: 1,
              height: 40,
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
          Expanded(
            child: _buildMiniStat(
              Icons.hourglass_empty,
              state.wallet != null
                  ? _formatCurrency(state.wallet!.pendingBalance)
                  : '0',
              l10n.pendingBalance,
              AppColors.warning,
              isDark,
            ),
          ),
          Container(
              width: 1,
              height: 40,
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
          Expanded(
            child: _buildMiniStat(
              Icons.account_balance,
              state.wallet != null
                  ? _formatCurrency(state.wallet!.totalWithdrawn)
                  : '0',
              l10n.totalWithdrawn,
              isDark ? Colors.grey[400]! : Colors.grey[600]!,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    IconData icon,
    String value,
    String label,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildBankInfo(
    BuildContext context,
    WalletState state,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    if (state.wallet == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.noBankLinked,
              style: TextStyle(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(l10n.linkBankNow),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection(
    BuildContext context,
    WalletState state,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    final filterLabels = [
      l10n.allTransactions,
      l10n.earnings,
      l10n.withdrawals,
      l10n.refunds,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.transactionHistory,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: primaryColor,
          unselectedLabelColor:
              isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
          indicatorColor: primaryColor,
          tabAlignment: TabAlignment.start,
          tabs: filterLabels.map((label) => Tab(text: label)).toList(),
        ),
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(state, isDark, l10n),
              _buildTransactionList(state, isDark, l10n),
              _buildTransactionList(state, isDark, l10n),
              _buildTransactionList(state, isDark, l10n),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList(
      WalletState state, bool isDark, AppLocalizations l10n) {
    if (state.loadStatus == WalletLoadStatus.loading &&
        state.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noNotifications,
              style: TextStyle(
                color:
                    isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.transactions.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.transactions.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final transaction = state.transactions[index];
        return TransactionItem(
          transaction: transaction,
          onTap: () =>
              _showTransactionDetail(context, transaction, isDark, l10n),
        );
      },
    );
  }

  void _showTransactionDetail(
    BuildContext context,
    Transaction transaction,
    bool isDark,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.description ?? l10n.transactionAmount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(
              l10n.transactionAmount,
              _formatCurrency(transaction.amount),
              isDark,
            ),
            _detailRow(
              l10n.transactionDate,
              _formatDateTime(transaction.createdAt),
              isDark,
            ),
            _detailRow('ID', transaction.id.substring(0, 8), isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(
      BuildContext context, AppLocalizations l10n, double balance) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.withdrawSuccess),
        content: Text(
            '${l10n.balanceAvailable}: ${_formatCurrency(balance)} VND'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
