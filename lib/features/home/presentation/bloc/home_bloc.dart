import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/location_service.dart';
import '../../../../services/driver_realtime_service.dart';
import '../../../../features/driver/domain/repositories/driver_repository.dart';
import '../../../../features/orders/domain/repositories/order_repository.dart';
import '../../../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../../../models/driver_realtime_payloads.dart';
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

  StreamSubscription? _profileSub;
  StreamSubscription? _activeOrderSub;
  StreamSubscription? _recentOrdersSub;
  StreamSubscription? _statsSub;
  StreamSubscription? _walletSub;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription<DriverRealtimeOrderRequest>? _orderRequestSub;
  StreamSubscription<DriverRealtimeOrderStatus>? _orderStatusSub;
  StreamSubscription<String>? _realtimeConnectionSub;
  Timer? _locationTimer;

  String? _currentDriverId;
  final Set<String> _activeRequestIds = <String>{};
  final Set<String> _dismissedRequestIds = <String>{};
  Timer? _availableOrdersPollingTimer;

  HomeBloc({
    required HomeRepository homeRepository,
    required DriverRepository driverRepository,
    required OrderRepository orderRepository,
    required WalletRepository walletRepository,
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
    on<ActiveOrderUpdated>(_onActiveOrderUpdated);
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
  }

  Future<String> _getDriverId() async {
    return await _secureStorage.read(key: AppConstants.driverIdKey) ?? '';
  }

  void _cancelAllSubscriptions() {
    _profileSub?.cancel();
    _activeOrderSub?.cancel();
    _recentOrdersSub?.cancel();
    _statsSub?.cancel();
    _walletSub?.cancel();
    _orderRequestSub?.cancel();
    _orderStatusSub?.cancel();
    _realtimeConnectionSub?.cancel();
    _stopAvailableOrdersPolling();
    _profileSub = null;
    _activeOrderSub = null;
    _recentOrdersSub = null;
    _statsSub = null;
    _walletSub = null;
    _orderRequestSub = null;
    _orderStatusSub = null;
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
            try {
              await _driverRepository.updateDriverLocation(
                position.latitude,
                position.longitude,
                heading: position.heading,
                speed: position.speed,
              );
            } catch (e) {
              debugPrint('[HomeBloc] Location stream update error: $e');
              // Retry once after a short delay
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
          },
          onError: (e) {
            debugPrint('[HomeBloc] Location stream error: $e');
          },
        );

    _locationTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      if (!isClosed && state.isOnline) {
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
          // Retry once after 5 seconds if the first attempt fails
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

  Future<void> _onHomeLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

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

      _profileSub = _homeRepository.watchDriverProfile(driverId).listen((
        profile,
      ) {
        add(ProfileUpdated(profile));
      });

      _activeOrderSub = _homeRepository.watchCurrentOrder(driverId).listen((
        order,
      ) {
        add(ActiveOrderUpdated(order));
      });

      _recentOrdersSub = _homeRepository.watchRecentOrders(driverId).listen((
        orders,
      ) {
        add(RecentOrdersUpdated(orders));
      });

      _statsSub = _homeRepository.watchDriverStats(driverId).listen((data) {
        add(StatsUpdated(data));
      });

      // Tam thoi bo wallet stream de tranh loi permission-denied tu Firestore.
      // _walletSub = _homeRepository.watchWallet(driverId).listen((wallet) {
      //   add(WalletUpdated(wallet));
      // });

      await _connectRealtime();
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

    // Send initial location after state update, ignore failures
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
      emit(state.copyWith(isAcceptingOrder: false));
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
      emit(state.copyWith(isUpdatingStatus: false));
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
    final isDriverOnline = event.profile?.isActive ?? false;

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

  void _onActiveOrderUpdated(
    ActiveOrderUpdated event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(activeOrder: event.order));
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
          ordersToday: data['ordersToday'] ?? 0,
          earningsToday: (data['earningsToday'] ?? 0.0).toDouble(),
          balance: (data['balance'] ?? 0.0).toDouble(),
          totalOrders: data['totalOrders'] ?? 0,
          rating: (data['rating'] ?? 0.0).toDouble(),
        ),
      ),
    );
  }

  void _onWalletUpdated(WalletUpdated event, Emitter<HomeState> emit) {
    emit(state.copyWith(wallet: event.wallet));
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
      '[HomeBloc] Foreground FCM signal received - orderId=${event.orderId}, requestId=${event.requestId}, dismissed=$isDismissed, active=$isActive, pending=$isPending, existsInQueue=$existsInQueue',
    );

    if (isDismissed || isActive || isPending || existsInQueue) {
      debugPrint(
        '[HomeBloc] Ignoring FCM signal - orderId=${event.orderId}, dismissed=$isDismissed, active=$isActive, pending=$isPending, existsInQueue=$existsInQueue',
      );
      return;
    }

    if (event.requestId == null || event.requestId!.isEmpty) {
      debugPrint(
        '[HomeBloc] Foreground FCM signal for order: ${event.orderId}. Waiting for WebSocket payload.',
      );
      return;
    }

    try {
      debugPrint(
        '[HomeBloc] Ensuring websocket connection after FCM signal - orderId=${event.orderId}, requestId=${event.requestId}',
      );
      await _connectRealtime();
    } catch (e) {
      debugPrint('[HomeBloc] Failed to ensure websocket connection after FCM signal: $e');
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
      emit(
        state.copyWith(
          orderRequests: remainingRequests,
          pendingRequest:
              remainingRequests.isEmpty ? null : remainingRequests.first,
          clearPendingRequest: remainingRequests.isEmpty,
          clearErrorMessage: true,
          successMessage: 'Da nhan don hang thanh cong.',
          isAcceptingOrder: false,
        ),
      );
      add(const HomeLoadRequested(resetStreams: false));
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

    if (payload.isAcceptFailed || payload.isDeclineFailed || payload.isError) {
      emit(
        state.copyWith(
          orderRequests: remainingRequests,
          pendingRequest:
              remainingRequests.isEmpty ? null : remainingRequests.first,
          clearPendingRequest: remainingRequests.isEmpty,
          errorMessage: payload.message ?? 'Khong the xu ly yeu cau don hang.',
          clearSuccessMessage: true,
          isAcceptingOrder: false,
        ),
      );
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
      source: 'websocket',
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
              'Khong the xu ly yeu cau don hang nay vi thieu requestId hop le.',
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
        clearErrorMessage: true,
      ),
    );

    emit(
      state.copyWith(
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
        await _orderRepository.respondOrder(
          event.orderId,
          event.action,
          event.requestId,
        );
        emit(
          state.copyWith(
            isAcceptingOrder: false,
            clearErrorMessage: true,
            successMessage: event.action == 'accept'
                ? 'Da nhan don hang thanh cong.'
                : 'Da tu choi don hang.',
          ),
        );
        if (event.action == 'accept') {
          add(const HomeLoadRequested());
        }
      } catch (e) {
        emit(
          state.copyWith(
            isAcceptingOrder: false,
            clearSuccessMessage: true,
            errorMessage: 'Khong the xu ly yeu cau: $e',
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
      '[HomeBloc] _connectRealtime invoked - hasOrderRequestSub=${_orderRequestSub != null}, hasOrderStatusSub=${_orderStatusSub != null}, serviceConnected=${_driverRealtimeService.isConnected}, currentDriverId=$_currentDriverId',
    );

    if (_orderRequestSub != null && _orderStatusSub != null) {
      if (_driverRealtimeService.isConnected) {
        debugPrint('[HomeBloc] Realtime already connected, keeping existing subscriptions');
        _startAvailableOrdersPolling();
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
      _realtimeConnectionSub = _driverRealtimeService.connectionStates.listen(
        (state) => debugPrint('[HomeBloc] WebSocket state: $state'),
      );
    }

    await _driverRealtimeService.connect();
    debugPrint('[HomeBloc] Realtime connect() completed');
    _startAvailableOrdersPolling();
  }

  void _disconnectRealtime() {
    unawaited(_driverRealtimeService.disconnect());
    _stopAvailableOrdersPolling();
    debugPrint('[HomeBloc] Realtime disconnected');
  }


  void _startAvailableOrdersPolling() {
    if (_availableOrdersPollingTimer != null) return;

    _availableOrdersPollingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => add(const HomeLoadRequested()),
    );
  }

  void _stopAvailableOrdersPolling() {
    _availableOrdersPollingTimer?.cancel();
    _availableOrdersPollingTimer = null;
  }

  @override
  Future<void> close() {
    _cancelAllSubscriptions();
    _stopLocationUpdates();
    _disconnectRealtime();
    return super.close();
  }
}
