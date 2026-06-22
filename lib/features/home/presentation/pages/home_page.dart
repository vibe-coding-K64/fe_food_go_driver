import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../injection_container.dart';
import '../../../../services/background_location_service_manager.dart';
import '../../../driver/domain/repositories/driver_repository.dart';
import '../../../auth/presentation/bloc/login_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/driver_info_card.dart';
import '../widgets/active_order_panel.dart';
import '../widgets/today_stats_card.dart';
import '../widgets/order_request_modal.dart';
import '../widgets/available_orders_section.dart';
import 'available_orders_screen.dart';
import 'order_detail_screen.dart';

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
    _initBackgroundService();
  }

  Future<void> _initBackgroundService() async {
    _bgService.initialize(driverRepository: getIt<DriverRepository>());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final homeState = context.read<HomeBloc>().state;
    final hasActiveOrder = homeState.activeOrders.isNotEmpty;
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

  Future<void> _onRefresh() async {
    context.read<HomeBloc>().add(const RefreshAllDataRequested());
  }

  Future<void> _handleTakePhoto(BuildContext context, HomeState state, String orderId) async {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.complete,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.takeDeliveryPhotoToComplete,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryLight),
                title: Text(l10n.takePhoto),
                subtitle: Text(l10n.takePhotoDescription),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadPhoto(context, orderId, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryLight),
                title: Text(l10n.selectFromGallery),
                subtitle: Text(l10n.selectFromGalleryDescription),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadPhoto(context, orderId, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
    BuildContext context,
    String orderId,
    ImageSource source,
  ) async {

    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return;

      context.read<HomeBloc>().add(
        CompleteOrderWithPhotoPressed(
          orderId: orderId,
          photoPath: photo.path,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.imagePickerError(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          previous.activeOrders.length != current.activeOrders.length ||
          previous.isOnline != current.isOnline,
      listener: (context, state) {
        if (state.activeOrders.isNotEmpty && state.isOnline) {
          // Order started - if app is already in background, start service immediately
          final lifecycleState = WidgetsBinding.instance.lifecycleState;
          if (lifecycleState == AppLifecycleState.paused ||
              lifecycleState == AppLifecycleState.inactive ||
              lifecycleState == AppLifecycleState.hidden) {
            _startBackgroundLocation();
          }
        } else {
          // No active orders - stop background location
          _stopBackgroundLocation();
        }
      },
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (previous, current) =>
            previous.pendingRequest != current.pendingRequest ||
            previous.successMessage != current.successMessage ||
            previous.errorMessage != current.errorMessage ||
            previous.needsReLogin != current.needsReLogin ||
            previous.unreadChatMessage != current.unreadChatMessage,
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

          if (state.successMessage != null &&
              state.successMessage!.isNotEmpty) {
            _showInfoDialog(
              context,
              l10n.notifications,
              state.successMessage!,
              AppColors.success,
              Icons.check_circle,
              l10n,
            );
            context.read<HomeBloc>().add(const ClearSuccessMessage());
          }

          if (state.errorMessage != null &&
              state.errorMessage!.isNotEmpty &&
              !state.needsLocationPermission) {
            _showInfoDialog(
              context,
              l10n.notifications,
              state.errorMessage!,
              isDark ? AppColors.errorDark : AppColors.errorLight,
              Icons.error_outline,
              l10n,
            );
            context.read<HomeBloc>().add(const ClearErrorMessage());
          }

          if (state.unreadChatMessage != null &&
              state.unreadChatMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.unreadChatMessage!),
                backgroundColor: primaryColor,
                duration: const Duration(seconds: 4),
              ),
            );
            context.read<HomeBloc>().add(const ClearUnreadChatMessage());
          }
        },
        builder: (context, state) {
          if (state.status == HomeStatus.loading ||
              state.driverProfile == null) {
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
                  if (state.activeOrders.isNotEmpty) ...[
                    ...state.activeOrders.map((order) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ActiveOrderPanel(
                        order: order,
                        isUpdatingStatus: state.isUpdatingStatus,
                        isUploadingPhoto: state.isUploadingPhoto,
                        onPickedUp: () {
                          context.read<HomeBloc>().add(
                            ConfirmPickupPressed(order.id),
                          );
                        },
                        onDelivered: () {},
                        onCancelled: () {
                          _showCancelConfirmation(context, l10n, order.id);
                        },
                        onTakePhoto: () => _handleTakePhoto(context, state, order.id),
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
                    )),
                  ],
                  if (state.isOnline && state.availableOrders.isNotEmpty) ...[
                    AvailableOrdersSection(
                      availableOrders: state.availableOrders,
                      onRefresh: _onRefresh,
                      onViewAll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<HomeBloc>(),
                              child: const AvailableOrdersScreen(),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!state.isOnline && state.activeOrders.isEmpty)
                    _buildOfflinePrompt(context, l10n, isDark, primaryColor),
                  TodayStatsCard(stats: state.todayStats),
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

  void _showCancelConfirmation(BuildContext context, AppLocalizations l10n, String orderId) {
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
      debugPrint(
        '[HomePage] Skipping order request modal because pendingRequest is null',
      );
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
      '[HomePage] Scheduling order request modal - orderId=${request.orderId}, requestId=${request.id}, expiresAt=${request.expiresAt}',
    );
    setState(() => _isModalShowing = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        debugPrint(
          '[HomePage] Context unmounted before showing order request modal',
        );
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

  void _showInfoDialog(
    BuildContext context,
    String title,
    String message,
    Color color,
    IconData icon,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
