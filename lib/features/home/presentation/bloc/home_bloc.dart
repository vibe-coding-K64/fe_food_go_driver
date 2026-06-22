import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/location_service.dart';
import '../../../../services/driver_realtime_service.dart';
import '../../../../models/driver_realtime_payloads.dart';
import '../../../../features/driver/domain/repositories/driver_repository.dart';
import '../../../../features/orders/domain/repositories/order_repository.dart';
import '../../../../features/orders/domain/entities/order.dart';
import '../../../orders/data/models/order_request_model.dart';
import '../../data/repositories/home_repository_impl.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  final DriverRepository _driverRepository;
  final OrderRepository _orderRepository;
  final FlutterSecureStorage _secureStorage;
  final LocationService _locationService;
  final DriverRealtimeService _driverRealtimeService;

  StreamSubscription? _orderRequestSub;
  StreamSubscription? _orderStatusSub;
  StreamSubscription<DriverRealtimeChatMessage>? _chatMessageSub;
  StreamSubscription<String>? _realtimeConnectionSub;
  Timer? _locationTimer;

  String? _currentDriverId;
  final Set<String> _activeRequestIds = <String>{};
  final Set<String> _dismissedRequestIds = <String>{};

  HomeBloc({
    required HomeRepository homeRepository,
    required DriverRepository driverRepository,
    required OrderRepository orderRepository,
    required FlutterSecureStorage secureStorage,
    required DriverRealtimeService driverRealtimeService,
    LocationService? locationService,
  }) : _homeRepository = homeRepository,
       _driverRepository = driverRepository,
       _orderRepository = orderRepository,
       _secureStorage = secureStorage,
       _driverRealtimeService = driverRealtimeService,
       _locationService = locationService ?? LocationService(),
       super(const HomeState()) {
    on<HomeLoadRequested>(_onHomeLoadRequested);
    on<HomeStopListening>(_onHomeStopListening);
    on<ToggleDriverStatus>(_onToggleDriverStatus);
    on<SetDriverOnlineRequested>(_onSetDriverOnline);
    on<SetDriverOfflineRequested>(_onSetDriverOffline);
    on<AcceptOrderRequested>(_onAcceptOrder);
    on<ConfirmPickupPressed>(_onConfirmPickup);
    on<CompleteOrderPressed>(_onConfirmDelivered);
    on<CancelOrderPressed>(_onCancelOrderPressed);
    on<ProfileUpdated>(_onProfileUpdated);
    on<ActiveOrdersUpdated>(_onActiveOrdersUpdated);
    on<RecentOrdersUpdated>(_onRecentOrdersUpdated);
    on<StatsUpdated>(_onStatsUpdated);
    on<WalletUpdated>(_onWalletUpdated);
    on<ClearErrorMessage>(_onClearErrorMessage);
    on<ClearSuccessMessage>(_onClearSuccessMessage);
    on<ClearLocationPermissionRequest>(_onClearLocationPermissionRequest);
    on<TriggerReLogin>(_onTriggerReLogin);
    on<ForegroundFcmOrderSignalReceived>(_onForegroundFcmOrderSignalReceived);
    on<DismissOrderRequestPrompt>(_onDismissOrderRequestPrompt);
    on<RespondToOrderRequest>(_onRespondToOrderRequest);
    on<RealtimeOrderStatusReceived>(_onRealtimeOrderStatusReceived);
    on<RealtimeOrderRequestReceived>(_onRealtimeOrderRequestReceived);
    on<LoadWalletRequested>(_onLoadWalletRequested);
    on<LoadStatsRequested>(_onLoadStatsRequested);
    on<RefreshAllDataRequested>(_onRefreshAllDataRequested);
    on<AvailableOrdersUpdated>(_onAvailableOrdersUpdated);
    on<RefreshAvailableOrdersRequested>(_onRefreshAvailableOrdersRequested);
    on<AcceptAvailableOrder>(_onAcceptAvailableOrder);
    on<DeclineAvailableOrder>(_onDeclineAvailableOrder);
    on<CompleteOrderWithPhotoPressed>(_onCompleteOrderWithPhotoPressed);
    on<RealtimeChatMessageReceived>(_onRealtimeChatMessageReceived);
    on<ClearUnreadChatMessage>(_onClearUnreadChatMessage);
    on<SetCurrentChatOrder>(_onSetCurrentChatOrder);
    on<ReportOrderIssue>(_onReportOrderIssue);
  }

  Future<String> _getDriverId() async {
    return await _secureStorage.read(key: AppConstants.driverIdKey) ?? '';
  }

  void _cancelAllSubscriptions() {
    _orderRequestSub?.cancel();
    _orderStatusSub?.cancel();
    _chatMessageSub?.cancel();
    _realtimeConnectionSub?.cancel();
    _orderRequestSub = null;
    _orderStatusSub = null;
    _chatMessageSub = null;
    _realtimeConnectionSub = null;
  }

  void _startLocationUpdates() {
    _stopLocationUpdates();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _locationSub =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (position) async {
            if (!isClosed && !state.isOnline) return;
            try {
              await _driverRepository.updateDriverLocation(
                position.latitude,
                position.longitude,
                heading: position.heading,
                speed: position.speed,
              );
            } catch (e) {
              debugPrint('[HomeBloc] Location stream update error: $e');
              if (!isClosed && state.isOnline) {
                try {
                  await Future.delayed(const Duration(seconds: 3));
                  await _driverRepository.updateDriverLocation(
                    position.latitude,
                    position.longitude,
                    heading: position.heading,
                    speed: position.speed,
                  );
                } catch (e2) {
                  debugPrint('[HomeBloc] Location stream retry failed: $e2');
                }
              }
            }
          },
          onError: (e) {
            debugPrint('[HomeBloc] Location stream error: $e');
          },
        );

    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!isClosed) {
        try {
          final (position, _) = await _locationService.getCurrentPosition();
          if (position != null) {
            await _driverRepository.updateDriverLocation(
              position.latitude,
              position.longitude,
              heading: position.heading,
              speed: position.speed,
            );
          }
        } catch (e) {
          try {
            await Future.delayed(const Duration(seconds: 5));
            final (position, _) = await _locationService.getCurrentPosition();
            if (position != null) {
              await _driverRepository.updateDriverLocation(
                position.latitude,
                position.longitude,
                heading: position.heading,
                speed: position.speed,
              );
            }
          } catch (e2) {
            debugPrint('[HomeBloc] Location timer retry failed: $e2');
          }
        }
      }
    });
  }

  void _stopLocationUpdates() {
    _locationSub?.cancel();
    _locationSub = null;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  StreamSubscription<Position>? _locationSub;

  Future<void> _onRefreshAllDataRequested(
    RefreshAllDataRequested event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint('[HomeBloc] _onRefreshAllDataRequested START');
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) {
      debugPrint('[HomeBloc] driverId is empty, skipping');
      return;
    }
    debugPrint('[HomeBloc] _onRefreshAllDataRequested driverId=$driverId');

    try {
      final profile = await _homeRepository.fetchDriverProfile(driverId);
      debugPrint('[HomeBloc] fetchDriverProfile success, name=${profile.fullName}');
      add(ProfileUpdated(profile));
    } catch (e) {
      debugPrint('[HomeBloc] Refresh profile failed: $e');
    }

    try {
      final stats = await _homeRepository.fetchDriverStats();
      add(StatsUpdated(stats));
    } catch (e) {
      debugPrint('[HomeBloc] Refresh stats failed: $e');
    }

    try {
      final available = await _homeRepository.fetchAvailableOrders();
      debugPrint('[HomeBloc] fetchAvailableOrders returned count=${available.length}');
      add(AvailableOrdersUpdated(available));
    } catch (e) {
      debugPrint('[HomeBloc] Refresh available orders failed: $e');
    }

    try {
      final orders = await _homeRepository.fetchActiveOrders();
      add(ActiveOrdersUpdated(orders.cast<Order>()));
    } catch (e) {
      debugPrint('[HomeBloc] Refresh active orders failed: $e');
    }

    try {
      final orders = await _homeRepository.fetchRecentOrders(limit: 20);
      add(RecentOrdersUpdated(orders));
    } catch (e) {
      debugPrint('[HomeBloc] Refresh recent orders failed: $e');
    }

    try {
      final wallet = await _homeRepository.fetchWallet(driverId);
      if (wallet != null) {
        add(WalletUpdated(wallet));
      }
    } catch (e) {
      debugPrint('[HomeBloc] Refresh wallet failed: $e');
    }
  }

  Future<void> _onHomeLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (event.resetStreams) {
      emit(state.copyWith(status: HomeStatus.loading));
    }

    final driverId = await _getDriverId();
    if (driverId.isEmpty) {
      emit(state.copyWith(status: HomeStatus.loaded));
      return;
    }

    _currentDriverId = driverId;

    if (event.resetStreams) {
      _activeRequestIds.clear();
      _dismissedRequestIds.clear();
      _cancelAllSubscriptions();

      _orderRequestSub = _driverRealtimeService.orderRequests.listen(
        (payload) => add(RealtimeOrderRequestReceived(payload)),
      );
      _orderStatusSub = _driverRealtimeService.orderStatuses.listen(
        (status) => add(RealtimeOrderStatusReceived(status)),
      );
      _chatMessageSub = _driverRealtimeService.chatMessages.listen(
        (msg) => add(RealtimeChatMessageReceived(msg)),
      );
      _realtimeConnectionSub = _driverRealtimeService.connectionStates.listen(
        (state) => debugPrint('[HomeBloc] WebSocket state: $state'),
      );

      await _connectRealtime();

      add(const RefreshAllDataRequested());
    } else {
      debugPrint(
        '[HomeBloc] Skipping stream reset for HomeLoadRequested(resetStreams: false)',
      );
    }

    emit(state.copyWith(status: HomeStatus.loaded));
  }

  void _onHomeStopListening(HomeStopListening event, Emitter<HomeState> emit) {
    _cancelAllSubscriptions();
    _stopLocationUpdates();
    _disconnectRealtime();
    _activeRequestIds.clear();
    _dismissedRequestIds.clear();
    _currentDriverId = null;
  }

  Future<void> _onToggleDriverStatus(
    ToggleDriverStatus event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    if (state.isTogglingStatus) return;

    if (state.isOnline) {
      await _handleGoOffline(emit);
    } else {
      await _handleGoOnline(emit);
    }
  }

  Future<void> _handleGoOnline(Emitter<HomeState> emit) async {
    emit(state.copyWith(isTogglingStatus: true, clearErrorMessage: true));

    final (position, failure) = await _locationService.getCurrentPosition();

    if (failure != null) {
      if (failure is LocationServiceDisabledFailure) {
        emit(
          state.copyWith(
            isTogglingStatus: false,
            needsLocationPermission: true,
            errorMessage: failure.message,
          ),
        );
      } else if (failure is LocationPermissionDeniedFailure) {
        emit(
          state.copyWith(
            isTogglingStatus: false,
            needsLocationPermission: true,
            errorMessage: failure.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isTogglingStatus: false,
            errorMessage: failure.message,
          ),
        );
      }
      return;
    }

    try {
      await _driverRepository.updateDriverStatus(
        true,
        lat: position!.latitude,
        lng: position.longitude,
      );
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
      return;
    } catch (e) {
      emit(
        state.copyWith(
          isTogglingStatus: false,
          errorMessage: 'Failed to go online: $e',
        ),
      );
      return;
    }

    _startLocationUpdates();
    _connectRealtime();
    emit(
      state.copyWith(
        isTogglingStatus: false,
        isOnline: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _driverRepository.updateDriverLocation(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint(
        '[HomeBloc] Initial location update failed (will retry via timer): $e',
      );
    }
  }

  Future<void> _handleGoOffline(Emitter<HomeState> emit) async {
    emit(state.copyWith(isTogglingStatus: true, clearErrorMessage: true));

    try {
      _stopLocationUpdates();
      _disconnectRealtime();
      await _driverRepository.updateDriverStatus(false);
      emit(
        state.copyWith(
          isTogglingStatus: false,
          isOnline: false,
          clearErrorMessage: true,
        ),
      );
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
    } catch (e) {
      emit(
        state.copyWith(
          isTogglingStatus: false,
          errorMessage: 'Failed to go offline: $e',
        ),
      );
    }
  }

  Future<void> _onSetDriverOnline(
    SetDriverOnlineRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isTogglingStatus: true, clearErrorMessage: true));

    try {
      await _driverRepository.updateDriverStatus(
        true,
        lat: event.latitude,
        lng: event.longitude,
      );
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
      return;
    } catch (e) {
      emit(
        state.copyWith(
          isTogglingStatus: false,
          errorMessage: 'Failed to go online: $e',
        ),
      );
      return;
    }

    _startLocationUpdates();
    await _connectRealtime();
    emit(
      state.copyWith(
        isTogglingStatus: false,
        isOnline: true,
        clearErrorMessage: true,
      ),
    );

    try {
      await _driverRepository.updateDriverLocation(
        event.latitude,
        event.longitude,
      );
    } catch (e) {
      debugPrint(
        '[HomeBloc] Initial location update failed (will retry via timer): $e',
      );
    }
  }

  Future<void> _onSetDriverOffline(
    SetDriverOfflineRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isTogglingStatus: true, clearErrorMessage: true));

    try {
      _stopLocationUpdates();
      await _driverRepository.updateDriverStatus(false);
      emit(
        state.copyWith(
          isTogglingStatus: false,
          isOnline: false,
          clearErrorMessage: true,
        ),
      );
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
    } catch (e) {
      emit(
        state.copyWith(
          isTogglingStatus: false,
          errorMessage: 'Failed to go offline: $e',
        ),
      );
    }
  }

  void _onClearErrorMessage(ClearErrorMessage event, Emitter<HomeState> emit) {
    emit(state.copyWith(clearErrorMessage: true));
  }

  void _onClearSuccessMessage(
    ClearSuccessMessage event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(clearSuccessMessage: true));
  }

  void _onClearLocationPermissionRequest(
    ClearLocationPermissionRequest event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(needsLocationPermission: false));
  }

  void _onTriggerReLogin(TriggerReLogin event, Emitter<HomeState> emit) {
    _disconnectRealtime();
    emit(state.copyWith(needsReLogin: true));
  }

  void _handleAuthFailure(Emitter<HomeState> emit) {
    _disconnectRealtime();
    emit(state.copyWith(needsReLogin: true));
  }

  Future<void> _onAcceptOrder(
    AcceptOrderRequested event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    emit(state.copyWith(isAcceptingOrder: true));

    try {
      await _orderRepository.acceptOrder(driverId, event.orderId);
      final orders = await _homeRepository.fetchActiveOrders();
      emit(state.copyWith(
        isAcceptingOrder: false,
        activeOrders: orders,
      ));
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
    } catch (e) {
      emit(
        state.copyWith(
          isAcceptingOrder: false,
          errorMessage: 'Failed to accept order: $e',
        ),
      );
    }
  }

  Future<void> _onCompleteOrderWithPhotoPressed(
    CompleteOrderWithPhotoPressed event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    emit(state.copyWith(isUploadingPhoto: true));

    try {
      final photoFile = File(event.photoPath);
      if (!await photoFile.exists()) {
        emit(state.copyWith(
          isUploadingPhoto: false,
          errorMessage: 'Không tìm thấy ảnh. Vui lòng chụp lại.',
        ));
        return;
      }

      final order = await _orderRepository.confirmDeliveryWithPhoto(
        event.orderId,
        photoFile,
      );

      emit(state.copyWith(
        isUploadingPhoto: false,
      ));

      if (order != null) {
        _showSuccess(context: null, message: 'Giao hàng thành công!');
      }

      add(const RefreshAllDataRequested());
    } on AuthFailure catch (_) {
      emit(state.copyWith(isUploadingPhoto: false));
      _handleAuthFailure(emit);
    } catch (e) {
      emit(state.copyWith(
        isUploadingPhoto: false,
        errorMessage: 'Không thể xác nhận giao hàng: $e',
      ));
    }
  }

  void _showSuccess({required BuildContext? context, required String message}) {
    debugPrint('[HomeBloc] $message');
  }

  Future<void> _onConfirmDelivered(
    CompleteOrderPressed event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    emit(state.copyWith(isUpdatingStatus: true));

    try {
      await _orderRepository.updateOrderStatus(
        driverId,
        event.orderId,
        AppConstants.orderStatusDelivered,
      );
      emit(state.copyWith(isUpdatingStatus: false));
      add(const RefreshAllDataRequested());
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdatingStatus: false,
          errorMessage: 'Failed to complete order: $e',
        ),
      );
    }
  }

  Future<void> _onConfirmPickup(
    ConfirmPickupPressed event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    emit(state.copyWith(isUpdatingStatus: true));

    try {
      await _orderRepository.updateOrderStatus(
        driverId,
        event.orderId,
        AppConstants.orderStatusDelivering,
      );
      final orders = await _homeRepository.fetchActiveOrders();
      emit(state.copyWith(
        isUpdatingStatus: false,
        activeOrders: orders,
      ));
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdatingStatus: false,
          errorMessage: 'Failed to confirm pickup: $e',
        ),
      );
    }
  }

  Future<void> _onCancelOrderPressed(
    CancelOrderPressed event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    emit(state.copyWith(isUpdatingStatus: true));

    try {
      await _orderRepository.updateOrderStatus(
        driverId,
        event.orderId,
        AppConstants.orderStatusCancelled,
      );
      emit(state.copyWith(isUpdatingStatus: false));
    } on AuthFailure catch (_) {
      _handleAuthFailure(emit);
    } catch (e) {
      emit(
        state.copyWith(
          isUpdatingStatus: false,
          errorMessage: 'Failed to cancel order: $e',
        ),
      );
    }
  }

  void _onProfileUpdated(ProfileUpdated event, Emitter<HomeState> emit) {
    debugPrint('[HomeBloc] _onProfileUpdated profile=${event.profile?.fullName}, isActive=${event.profile?.isActive}');
    final isDriverOnline = event.profile?.isActive ?? false;

    if (isDriverOnline == state.isOnline &&
        event.profile == state.driverProfile) {
      debugPrint('[HomeBloc] _onProfileUpdated SKIP (no change)');
      return;
    }

    debugPrint('[HomeBloc] _onProfileUpdated state change: isOnline=${state.isOnline}->$isDriverOnline');
    if (isDriverOnline) {
      _startLocationUpdates();
      _connectRealtime();
    } else {
      _stopLocationUpdates();
      _disconnectRealtime();
    }

    emit(
      state.copyWith(
        driverProfile: event.profile,
        isOnline: isDriverOnline,
      ),
    );
  }

  void _onActiveOrdersUpdated(
    ActiveOrdersUpdated event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(activeOrders: event.orders.cast<Order>()));
  }

  void _onRecentOrdersUpdated(
    RecentOrdersUpdated event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(recentOrders: event.orders.cast()));
  }

  void _onStatsUpdated(StatsUpdated event, Emitter<HomeState> emit) {
    final data = event.stats as Map<String, dynamic>;
    emit(
      state.copyWith(
        todayStats: TodayStats(
          ordersToday: data['ordersToday'] ?? data['todayTrips'] ?? 0,
          earningsToday: (data['earningsToday'] ?? data['todayEarnings'] ?? 0.0).toDouble(),
          balance: (data['balance'] ?? 0.0).toDouble(),
          totalOrders: data['totalOrders'] ?? data['totalTrips'] ?? 0,
          rating: (data['rating'] ?? data['averageRating'] ?? 0.0).toDouble(),
        ),
      ),
    );
  }

  void _onAvailableOrdersUpdated(
    AvailableOrdersUpdated event,
    Emitter<HomeState> emit,
  ) {
    debugPrint('[HomeBloc] _onAvailableOrdersUpdated count=${event.orders.length}, orders=${
      event.orders.map((o) => '${o.id}').take(3).toList()
    }');
    emit(state.copyWith(availableOrders: event.orders.cast()));
  }

  Future<void> _onRefreshAvailableOrdersRequested(
    RefreshAvailableOrdersRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final available = await _homeRepository.fetchAvailableOrders();
      add(AvailableOrdersUpdated(available));
    } catch (e) {
      debugPrint('[HomeBloc] Refresh available orders failed: $e');
    }
  }

  Future<void> _onAcceptAvailableOrder(
    AcceptAvailableOrder event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    emit(state.copyWith(isAcceptingOrder: true));

    try {
      final order = await _orderRepository.acceptOrder(driverId, event.orderId);
      final updated = List.of(state.availableOrders)
        ..removeWhere((o) => o.id == event.orderId);
      if (order != null) {
        final activeOrders = await _homeRepository.fetchActiveOrders();
        emit(state.copyWith(
          isAcceptingOrder: false,
          activeOrders: activeOrders,
          availableOrders: updated.cast(),
        ));
      } else {
        emit(state.copyWith(
          isAcceptingOrder: false,
          availableOrders: updated.cast(),
          errorMessage: 'Đơn hàng đã được tài xế khác nhận.',
        ));
      }
    } on AuthFailure catch (_) {
      emit(state.copyWith(isAcceptingOrder: false));
      _handleAuthFailure(emit);
    } catch (e) {
      emit(state.copyWith(
        isAcceptingOrder: false,
        errorMessage: 'Không thể nhận đơn: $e',
      ));
    }
  }

  Future<void> _onDeclineAvailableOrder(
    DeclineAvailableOrder event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    try {
      await _homeRepository.declineAvailableOrder(event.orderId, driverId);
      final updated = List.of(state.availableOrders)
        ..removeWhere((o) => o.id == event.orderId);
      emit(state.copyWith(availableOrders: updated.cast()));
    } catch (e) {
      final updated = List.of(state.availableOrders)
        ..removeWhere((o) => o.id == event.orderId);
      emit(state.copyWith(
        availableOrders: updated.cast(),
        errorMessage: 'Không thể từ chối đơn: $e',
      ));
    }
  }

  void _onWalletUpdated(WalletUpdated event, Emitter<HomeState> emit) {
    emit(state.copyWith(wallet: event.wallet));
  }

  Future<void> _onLoadWalletRequested(
    LoadWalletRequested event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    try {
      final wallet = await _homeRepository.fetchWallet(driverId);
      if (wallet != null) {
        emit(state.copyWith(wallet: wallet));
      }
    } catch (e) {
      debugPrint('[HomeBloc] Failed to load wallet: $e');
    }
  }

  Future<void> _onLoadStatsRequested(
    LoadStatsRequested event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final data = await _homeRepository.fetchDriverStats();
      add(StatsUpdated(data));
    } catch (e) {
      debugPrint('[HomeBloc] Failed to load stats: $e');
    }
  }

  Future<void> _onForegroundFcmOrderSignalReceived(
    ForegroundFcmOrderSignalReceived event,
    Emitter<HomeState> emit,
  ) async {
    final isDismissed = _dismissedRequestIds.contains(event.orderId);
    final isActive = _activeRequestIds.contains(event.orderId);
    final isPending = state.pendingRequest?.orderId == event.orderId;
    final existsInQueue = state.orderRequests.any(
      (request) => request.orderId == event.orderId,
    );

    debugPrint(
      '[HomeBloc] Foreground push signal received - orderId=${event.orderId}, requestId=${event.requestId}, dismissed=$isDismissed, active=$isActive, pending=$isPending, existsInQueue=$existsInQueue',
    );

    if (isDismissed || isActive || isPending || existsInQueue) {
      debugPrint(
        '[HomeBloc] Ignoring push signal - orderId=${event.orderId}, dismissed=$isDismissed, active=$isActive, pending=$isPending, existsInQueue=$existsInQueue',
      );
      return;
    }

    if (event.requestId == null || event.requestId!.isEmpty) {
      debugPrint(
        '[HomeBloc] Foreground push signal for order: ${event.orderId}. Waiting for WebSocket payload.',
      );
      return;
    }

    try {
      debugPrint(
        '[HomeBloc] Ensuring websocket connection after push signal - orderId=${event.orderId}, requestId=${event.requestId}',
      );
      await _connectRealtime();
    } catch (e) {
      debugPrint('[HomeBloc] Failed to ensure websocket connection after push signal: $e');
    }
  }

  void _onDismissOrderRequestPrompt(
    DismissOrderRequestPrompt event,
    Emitter<HomeState> emit,
  ) {
    _dismissedRequestIds.add(event.orderId);

    final remainingRequests = state.orderRequests
        .where((request) => request.orderId != event.orderId)
        .toList();

    _activeRequestIds.remove(event.orderId);

    emit(
      state.copyWith(
        orderRequests: remainingRequests,
        pendingRequest:
            remainingRequests.isEmpty ? null : remainingRequests.first,
        clearPendingRequest: remainingRequests.isEmpty,
      ),
    );
  }

  void _onRealtimeOrderStatusReceived(
    RealtimeOrderStatusReceived event,
    Emitter<HomeState> emit,
  ) {
    final payload = event.payload;
    final orderId = payload.orderId;

    if (orderId != null && orderId.isNotEmpty) {
      _activeRequestIds.remove(orderId);
      _dismissedRequestIds.add(orderId);
    }

    final remainingRequests = orderId == null || orderId.isEmpty
        ? state.orderRequests
        : state.orderRequests
              .where((request) => request.orderId != orderId)
              .toList();

    if (payload.isAccepted) {
      final orderModel = payload.order;
      List<Order> updatedActive = List.of(state.activeOrders);
      if (orderModel != null) {
        final existingIndex = updatedActive.indexWhere((o) => o.id == orderModel.id);
        if (existingIndex >= 0) {
          updatedActive[existingIndex] = orderModel;
        } else {
          updatedActive = [...updatedActive, orderModel];
        }
      }
      emit(
        state.copyWith(
          orderRequests: remainingRequests,
          pendingRequest:
              remainingRequests.isEmpty ? null : remainingRequests.first,
          clearPendingRequest: remainingRequests.isEmpty,
          activeOrders: updatedActive,
          clearErrorMessage: true,
          successMessage: payload.message ?? 'Đã nhận đơn hàng thành công.',
          isAcceptingOrder: false,
        ),
      );
      add(const LoadStatsRequested());
      add(const LoadWalletRequested());
      return;
    }

    if (payload.isDeclined) {
      emit(
        state.copyWith(
          orderRequests: remainingRequests,
          pendingRequest:
              remainingRequests.isEmpty ? null : remainingRequests.first,
          clearPendingRequest: remainingRequests.isEmpty,
          clearErrorMessage: true,
          clearSuccessMessage: true,
          isAcceptingOrder: false,
        ),
      );
      return;
    }

    if (payload.isPickedUp) {
      List<Order> updatedActive = List.of(state.activeOrders);
      if (payload.order != null) {
        final idx = updatedActive.indexWhere((o) => o.id == payload.order!.id);
        if (idx >= 0) updatedActive[idx] = payload.order!;
      }
      emit(
        state.copyWith(
          activeOrders: updatedActive,
          clearErrorMessage: true,
          successMessage: payload.message ?? 'Đã xác nhận lấy hàng.',
          isUpdatingStatus: false,
        ),
      );
      return;
    }

    if (payload.isCompleted) {
      List<Order> updatedActive = state.activeOrders
          .where((o) => orderId != null && o.id != orderId)
          .toList();
      emit(
        state.copyWith(
          activeOrders: updatedActive,
          clearErrorMessage: true,
          successMessage: payload.message ?? 'Giao hàng thành công.',
          isUpdatingStatus: false,
        ),
      );
      add(const LoadStatsRequested());
      add(const LoadWalletRequested());
      return;
    }

    if (payload.isCancelled) {
      List<Order> updatedActive = state.activeOrders
          .where((o) => orderId != null && o.id != orderId)
          .toList();
      emit(
        state.copyWith(
          activeOrders: updatedActive,
          clearErrorMessage: true,
          successMessage: payload.message ?? 'Đơn hàng đã bị hủy.',
          isUpdatingStatus: false,
        ),
      );
      return;
    }

    if (payload.order != null) {
      List<Order> updatedActive = List.of(state.activeOrders);
      final idx = updatedActive.indexWhere((o) => o.id == payload.order!.id);
      if (idx >= 0) {
        updatedActive[idx] = payload.order!;
        emit(state.copyWith(activeOrders: updatedActive));
      }
    }
  }

  void _onRealtimeOrderRequestReceived(
    RealtimeOrderRequestReceived event,
    Emitter<HomeState> emit,
  ) {
    final payload = event.payload;
    final hasEmptyOrderId = payload.orderId.isEmpty;
    final hasEmptyRequestId = payload.requestId.isEmpty;
    final invalidEvent = payload.event != 'ORDER_REQUEST';
    final hasExpired = payload.hasExpired;
    final isDismissed = _dismissedRequestIds.contains(payload.orderId);
    final isActive = _activeRequestIds.contains(payload.orderId);
    final isPending = state.pendingRequest?.orderId == payload.orderId;
    final existsInQueue = state.orderRequests.any(
      (request) => request.orderId == payload.orderId,
    );

    debugPrint(
      '[HomeBloc] Realtime order request received - event=${payload.event}, orderId=${payload.orderId}, requestId=${payload.requestId}, expiresAt=${payload.expiresAt}, hasExpired=$hasExpired, dismissed=$isDismissed, active=$isActive, pending=$isPending, existsInQueue=$existsInQueue',
    );

    if (hasEmptyOrderId ||
        hasEmptyRequestId ||
        invalidEvent ||
        hasExpired ||
        isDismissed ||
        isActive ||
        isPending ||
        existsInQueue) {
      debugPrint(
        '[HomeBloc] Dropping realtime order request - orderId=${payload.orderId}, requestId=${payload.requestId}, hasEmptyOrderId=$hasEmptyOrderId, hasEmptyRequestId=$hasEmptyRequestId, invalidEvent=$invalidEvent, hasExpired=$hasExpired, dismissed=$isDismissed, active=$isActive, pending=$isPending, existsInQueue=$existsInQueue',
      );
      return;
    }

    final request = OrderRequestModel(
      id: payload.requestId,
      orderId: payload.orderId,
      driverId: _currentDriverId ?? '',
      status: 0,
      createdAt: DateTime.now(),
      orderData: payload.order,
      expiresAt: payload.expiresAt,
    );

    _activeRequestIds.add(payload.orderId);

    debugPrint(
      '[HomeBloc] Pending request set from realtime payload - orderId=${request.orderId}, requestId=${request.id}, queueSizeBefore=${state.orderRequests.length}',
    );

    emit(
      state.copyWith(
        orderRequests: [
          request,
          ...state.orderRequests.where(
            (existing) => existing.orderId != payload.orderId,
          ),
        ],
        pendingRequest: request,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _onRespondToOrderRequest(
    RespondToOrderRequest event,
    Emitter<HomeState> emit,
  ) async {
    debugPrint(
      '[HomeBloc] Responding to order request - action=${event.action}, orderId=${event.orderId}, requestId=${event.requestId}, pendingRequestId=${state.pendingRequest?.id}, queuedRequestIds=${state.orderRequests.map((request) => request.id).toList()}',
    );

    if (!event.hasValidRequestId) {
      emit(
        state.copyWith(
          errorMessage:
              'Không thể xử lý yêu cầu đơn hàng này vì thiếu requestId hợp lệ.',
        ),
      );
      return;
    }

    final updatedRequests = state.orderRequests
        .where((request) => request.orderId != event.orderId)
        .toList();

    _dismissedRequestIds.add(event.orderId);
    _activeRequestIds.remove(event.orderId);

    emit(
      state.copyWith(
        orderRequests: updatedRequests,
        pendingRequest:
            updatedRequests.isEmpty ? null : updatedRequests.first,
        clearPendingRequest: updatedRequests.isEmpty,
        isAcceptingOrder: event.action == 'accept',
        clearErrorMessage: true,
        clearSuccessMessage: true,
      ),
    );

    var sentViaWebsocket = false;
    try {
      sentViaWebsocket = event.action == 'accept'
          ? await _driverRealtimeService.sendAccept(
              orderId: event.orderId,
              requestId: event.requestId,
            )
          : await _driverRealtimeService.sendDecline(
              orderId: event.orderId,
              requestId: event.requestId,
            );
      debugPrint(
        '[HomeBloc] WebSocket response send result - action=${event.action}, orderId=${event.orderId}, requestId=${event.requestId}, sentViaWebsocket=$sentViaWebsocket',
      );
    } catch (e) {
      debugPrint('[HomeBloc] WebSocket respond failed: $e');
    }

    if (!sentViaWebsocket) {
      try {
        debugPrint(
          '[HomeBloc] Falling back to REST respondOrder - action=${event.action}, orderId=${event.orderId}, requestId=${event.requestId}',
        );
        if (event.action == 'accept') {
          await _orderRepository.respondOrder(
            event.orderId,
            event.action,
            event.requestId,
          );
          final activeOrders = await _homeRepository.fetchActiveOrders();
          emit(
            state.copyWith(
              isAcceptingOrder: false,
              activeOrders: activeOrders,
              clearErrorMessage: true,
              successMessage: 'Đã nhận đơn hàng thành công.',
            ),
          );
          add(const LoadStatsRequested());
          add(const LoadWalletRequested());
        } else {
          await _orderRepository.respondOrder(
            event.orderId,
            event.action,
            event.requestId,
          );
          emit(
            state.copyWith(
              isAcceptingOrder: false,
              clearErrorMessage: true,
              clearSuccessMessage: true,
            ),
          );
        }
      } catch (e) {
        emit(
          state.copyWith(
            isAcceptingOrder: false,
            clearSuccessMessage: true,
            errorMessage: 'Không thể xử lý yêu cầu: $e',
          ),
        );
      }
      return;
    }

    if (event.action != 'accept') {
      emit(state.copyWith(isAcceptingOrder: false, clearSuccessMessage: true));
    }
  }

  Future<void> _connectRealtime() async {
    debugPrint(
      '[HomeBloc] _connectRealtime invoked - hasOrderRequestSub=${_orderRequestSub != null}, hasOrderStatusSub=${_orderStatusSub != null}, hasChatMessageSub=${_chatMessageSub != null}, serviceConnected=${_driverRealtimeService.isConnected}, currentDriverId=$_currentDriverId',
    );

    if (_orderRequestSub != null && _orderStatusSub != null && _chatMessageSub != null) {
      if (_driverRealtimeService.isConnected) {
        debugPrint('[HomeBloc] Realtime already connected, keeping existing subscriptions');
        return;
      }
    } else {
      debugPrint('[HomeBloc] Creating realtime stream subscriptions');
      _orderRequestSub = _driverRealtimeService.orderRequests.listen(
        (payload) => add(RealtimeOrderRequestReceived(payload)),
      );
      _orderStatusSub = _driverRealtimeService.orderStatuses.listen(
        (status) => add(RealtimeOrderStatusReceived(status)),
      );
      _chatMessageSub = _driverRealtimeService.chatMessages.listen(
        (msg) => add(RealtimeChatMessageReceived(msg)),
      );
      _realtimeConnectionSub = _driverRealtimeService.connectionStates.listen(
        (state) => debugPrint('[HomeBloc] WebSocket state: $state'),
      );
    }

    await _driverRealtimeService.connect();
    debugPrint('[HomeBloc] Realtime connect() completed');
  }

  void _disconnectRealtime() {
    unawaited(_driverRealtimeService.disconnect());
    debugPrint('[HomeBloc] Realtime disconnected');
  }

  void _onRealtimeChatMessageReceived(
    RealtimeChatMessageReceived event,
    Emitter<HomeState> emit,
  ) {
    final msg = event.payload;
    debugPrint(
      '[HomeBloc] Chat message received - event=${msg.event}, conversationId=${msg.conversationId}, senderId=${msg.senderId}, senderName=${msg.senderName}, content=${msg.content}',
    );

    if (state.currentChatOrderId == msg.orderId) {
      debugPrint('[HomeBloc] Chat message skipped - already on chat screen for orderId=${msg.orderId}');
      return;
    }

    emit(state.copyWith(
      unreadChatMessage: 'Tin nhan tu ${msg.senderName}: ${msg.content}',
    ));
  }

  void _onClearUnreadChatMessage(
    ClearUnreadChatMessage event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(clearUnreadChatMessage: true));
  }

  void _onSetCurrentChatOrder(
    SetCurrentChatOrder event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(currentChatOrderId: event.orderId));
  }

  Future<bool> reportOrderIssue(
    String orderId,
    String reason,
    String? additionalNote,
  ) async {
    try {
      return await _orderRepository.reportOrderIssue(orderId, reason, additionalNote);
    } catch (e) {
      debugPrint('[HomeBloc] reportOrderIssue error: $e');
      return false;
    }
  }

  void _onReportOrderIssue(
    ReportOrderIssue event,
    Emitter<HomeState> emit,
  ) {
  }

  @override
  Future<void> close() {
    _cancelAllSubscriptions();
    _stopLocationUpdates();
    _disconnectRealtime();
    return super.close();
  }
}
