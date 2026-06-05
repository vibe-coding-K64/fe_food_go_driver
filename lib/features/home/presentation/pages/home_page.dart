import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/bloc/login_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../../services/fcm_service.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/driver_info_card.dart';
import '../widgets/active_order_panel.dart';
import '../widgets/today_stats_card.dart';
import '../widgets/wallet_summary_card.dart';
import '../widgets/recent_orders_list.dart';
import '../widgets/order_request_modal.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const HomePage({super.key, this.onNotificationTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isModalShowing = false;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeLoadRequested());
    _ensureFcmTokenRegistered();
  }

  Future<void> _ensureFcmTokenRegistered() async {
    try {
      final fcmService = getIt<FCMService>();
      final authRepo = getIt<AuthRepository>();
      final secureStorage = getIt<FlutterSecureStorage>();

      await fcmService.requestPermission();
      final fcmToken = await fcmService.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final token = await secureStorage.read(key: AppConstants.driverTokenKey);
      if (token == null || token.isEmpty) return;

      await authRepo.registerFcmToken(token, fcmToken);
      debugPrint('[HomePage] FCM token re-registered on app start');
    } catch (e) {
      debugPrint('[HomePage] FCM token registration failed: $e');
    }
  }

  Future<void> _onRefresh() async {
    context.read<HomeBloc>().add(const HomeLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.needsReLogin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => BlocProvider<LoginBloc>(
                create: (_) => getIt<LoginBloc>(),
                child: const LoginPage(),
              ),
            ),
            (route) => false,
          );
          return;
        }

        if (state.pendingRequest != null) {
          _showOrderRequestModal(context, state);
        }

        if (state.errorMessage != null &&
            state.errorMessage!.isNotEmpty &&
            !state.needsLocationPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor:
                  isDark ? AppColors.errorDark : AppColors.errorLight,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.read<HomeBloc>().add(const ClearErrorMessage());
                },
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == HomeStatus.loading && state.driverProfile == null) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DriverInfoCard(profile: state.driverProfile),
                const SizedBox(height: 16),
                if (state.activeOrder != null) ...[
                  ActiveOrderPanel(
                    order: state.activeOrder!,
                    isUpdatingStatus: state.isUpdatingStatus,
                    onPickedUp: () {
                      if (state.activeOrder != null) {
                        context.read<HomeBloc>().add(
                              CompleteOrderPressed(state.activeOrder!.id),
                            );
                      }
                    },
                    onDelivered: () {
                      if (state.activeOrder != null) {
                        context.read<HomeBloc>().add(
                              CompleteOrderPressed(state.activeOrder!.id),
                            );
                      }
                    },
                    onCancelled: () {
                      _showCancelConfirmation(context, l10n);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (!state.isOnline && state.activeOrder == null)
                  _buildOfflinePrompt(context, l10n, isDark, primaryColor),
                TodayStatsCard(stats: state.todayStats),
                const SizedBox(height: 16),
                WalletSummaryCard(
                  wallet: state.wallet,
                  onWithdraw: widget.onNotificationTap ?? () {},
                  onTransactionHistory: widget.onNotificationTap ?? () {},
                ),
                const SizedBox(height: 16),
                RecentOrdersList(
                  orders: state.recentOrders,
                  onRefresh: _onRefresh,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflinePrompt(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.offlinePrompt,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.searchingForOrders,
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
        ],
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, AppLocalizations l10n) {
    final state = context.read<HomeBloc>().state;
    final orderId = state.activeOrder?.id;
    if (orderId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrderWarning),
        content: Text(l10n.confirmCancelOrderMessage),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<HomeBloc>().add(CancelOrderPressed(orderId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.cancelOrder),
          ),
        ],
      ),
    );
  }

  void _showOrderRequestModal(BuildContext context, HomeState state) {
    final request = state.pendingRequest;
    if (request == null || _isModalShowing) return;

    final homeBloc = context.read<HomeBloc>();
    setState(() => _isModalShowing = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (ctx) => BlocProvider.value(
          value: homeBloc,
          child: OrderRequestModal(request: request, homeBloc: homeBloc),
        ),
      ).then((_) {
        if (mounted) setState(() => _isModalShowing = false);
      });
    });
  }
}
