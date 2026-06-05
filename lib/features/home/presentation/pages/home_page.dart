import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../injection_container.dart';
import '../../../../services/background_location_service_manager.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../driver/domain/repositories/driver_repository.dart';
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isModalShowing = false;
  final _bgService = BackgroundLocationServiceManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<HomeBloc>().add(const HomeLoadRequested());
    _ensureFcmTokenRegistered();
    _initBackgroundService();
  }

  Future<void> _initBackgroundService() async {
    _bgService.initialize(driverRepository: getIt<DriverRepository>());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final homeState = context.read<HomeBloc>().state;
    final hasActiveOrder = homeState.activeOrder != null;
    final isOnline = homeState.isOnline;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background
      if (hasActiveOrder && isOnline) {
        _startBackgroundLocation();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App back to foreground
      _stopBackgroundLocation();
    }
  }

  Future<void> _startBackgroundLocation() async {
    try {
      // Request background location permission if needed
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[HomePage] Background location permission not granted');
        return;
      }

      // Android 10+ requires ACCESS_BACKGROUND_LOCATION
      if (await Geolocator.isLocationServiceEnabled()) {
        await _bgService.startService();
        debugPrint('[HomePage] Background location service started');
      }
    } catch (e) {
      debugPrint('[HomePage] Failed to start background location: $e');
    }
  }

  void _stopBackgroundLocation() {
    if (_bgService.isRunning) {
      _bgService.stopService();
      debugPrint('[HomePage] Background location service stopped');
    }
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
    context.read<HomeBloc>().add(const LoadWalletRequested());
    context.read<HomeBloc>().add(const LoadStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          previous.activeOrder != current.activeOrder,
      listener: (context, state) {
        if (state.activeOrder != null && state.isOnline) {
          // Order started - if app is already in background, start service immediately
          final lifecycleState = WidgetsBinding.instance.lifecycleState;
          if (lifecycleState == AppLifecycleState.paused ||
              lifecycleState == AppLifecycleState.inactive ||
              lifecycleState == AppLifecycleState.hidden) {
            _startBackgroundLocation();
          }
        } else {
          // Order completed/cancelled
          _stopBackgroundLocation();
        }
      },
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (previous, current) =>
            previous.pendingRequest != current.pendingRequest ||
            previous.successMessage != current.successMessage ||
            previous.errorMessage != current.errorMessage ||
            previous.needsReLogin != current.needsReLogin,
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

        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: l10n.dismiss,
                textColor: Colors.white,
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  context.read<HomeBloc>().add(const ClearSuccessMessage());
                },
              ),
            ),
          );
          context.read<HomeBloc>().add(const ClearSuccessMessage());
        }

        if (state.errorMessage != null &&
            state.errorMessage!.isNotEmpty &&
            !state.needsLocationPermission) {
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
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
                label: l10n.dismiss,
                textColor: Colors.white,
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  context.read<HomeBloc>().add(const ClearErrorMessage());
                },
              ),
            ),
          );
          context.read<HomeBloc>().add(const ClearErrorMessage());
        }
      },
      builder: (context, state) {
        if (state.status == HomeStatus.loading || state.driverProfile == null) {
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
                              ConfirmPickupPressed(state.activeOrder!.id),
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
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgService.dispose();
    super.dispose();
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
    if (request == null) {
      debugPrint('[HomePage] Skipping order request modal because pendingRequest is null');
      return;
    }
    if (_isModalShowing) {
      debugPrint(
        '[HomePage] Skipping order request modal because another modal is already showing - orderId=${request.orderId}, requestId=${request.id}',
      );
      return;
    }

    final homeBloc = context.read<HomeBloc>();
    debugPrint(
      '[HomePage] Scheduling order request modal - orderId=${request.orderId}, requestId=${request.id}, source=${request.source}, expiresAt=${request.expiresAt}',
    );
    setState(() => _isModalShowing = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        debugPrint('[HomePage] Context unmounted before showing order request modal');
        if (mounted) setState(() => _isModalShowing = false);
        return;
      }
      debugPrint(
        '[HomePage] Showing order request modal - orderId=${request.orderId}, requestId=${request.id}',
      );
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
        debugPrint(
          '[HomePage] Order request modal closed - orderId=${request.orderId}, requestId=${request.id}',
        );
        if (mounted) setState(() => _isModalShowing = false);
      });
    });
  }
}
