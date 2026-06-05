import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../services/location_service.dart';
import '../../../../services/websocket_service.dart';
import '../../../../features/driver/domain/repositories/driver_repository.dart';
import '../../../../features/orders/domain/repositories/order_repository.dart';
import '../../../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../../orders/data/models/order_request_model.dart';
import '../../../orders/data/models/order_model.dart';
import '../../data/repositories/home_repository_impl.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  final DriverRepository _driverRepository;
  final OrderRepository _orderRepository;
  final FlutterSecureStorage _secureStorage;
  final LocationService _locationService;
  final WebSocketService _webSocketService;

  StreamSubscription? _profileSub;
  StreamSubscription? _activeOrderSub;
  StreamSubscription? _recentOrdersSub;
  StreamSubscription? _statsSub;
  StreamSubscription? _walletSub;
  StreamSubscription? _orderRequestsSub;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription? _wsOrderRequestSub;
  StreamSubscription? _wsOrderStatusSub;
  Timer? _locationTimer;

  String? _currentDriverId;

  HomeBloc({
    required HomeRepository homeRepository,
    required DriverRepository driverRepository,
    required OrderRepository orderRepository,
    required WalletRepository walletRepository,
    required FlutterSecureStorage secureStorage,
    required WebSocketService webSocketService,
    LocationService? locationService,
  }) : _homeRepository = homeRepository,
       _driverRepository = driverRepository,
       _orderRepository = orderRepository,
       _secureStorage = secureStorage,
       _locationService = locationService ?? LocationService(),
       _webSocketService = webSocketService,
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
    on<ClearLocationPermissionRequest>(_onClearLocationPermissionRequest);
    on<TriggerReLogin>(_onTriggerReLogin);
    on<OrderRequestsUpdated>(_onOrderRequestsUpdated);
    on<RespondToOrderRequest>(_onRespondToOrderRequest);
    on<WsOrderRequestReceived>(_onWsOrderRequestReceived);
    on<WsOrderStatusReceived>(_onWsOrderStatusReceived);
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
    _orderRequestsSub?.cancel();
    _wsOrderRequestSub?.cancel();
    _wsOrderStatusSub?.cancel();
    _profileSub = null;
    _activeOrderSub = null;
    _recentOrdersSub = null;
    _statsSub = null;
    _walletSub = null;
    _orderRequestsSub = null;
    _wsOrderRequestSub = null;
    _wsOrderStatusSub = null;
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

    await _connectWebSocket();

    emit(state.copyWith(status: HomeStatus.loaded));
  }

  void _onHomeStopListening(HomeStopListening event, Emitter<HomeState> emit) {
    _cancelAllSubscriptions();
    _stopLocationUpdates();
    _disconnectWebSocket();
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
    _connectWebSocket();
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
      _disconnectWebSocket();
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

  void _onClearLocationPermissionRequest(
    ClearLocationPermissionRequest event,
    Emitter<HomeState> emit,
  ) {
    emit(state.copyWith(needsLocationPermission: false));
  }

  void _onTriggerReLogin(TriggerReLogin event, Emitter<HomeState> emit) {
    _disconnectWebSocket();
    emit(state.copyWith(needsReLogin: true));
  }

  void _handleAuthFailure(Emitter<HomeState> emit) {
    _disconnectWebSocket();
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
    emit(
      state.copyWith(
        driverProfile: event.profile,
        isOnline: (event.profile?.isActive ?? false),
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

  void _onOrderRequestsUpdated(
    OrderRequestsUpdated event,
    Emitter<HomeState> emit,
  ) {
    final requests = event.requests.cast<OrderRequestModel>();
    final pending = requests.where((r) => r.isPending).toList();

    if (pending.isNotEmpty && state.pendingRequest == null) {
      emit(
        state.copyWith(orderRequests: pending, pendingRequest: pending.first),
      );
    } else if (pending.isEmpty) {
      emit(state.copyWith(orderRequests: const [], clearPendingRequest: true));
    } else {
      emit(state.copyWith(orderRequests: pending));
    }
  }

  Future<void> _onRespondToOrderRequest(
    RespondToOrderRequest event,
    Emitter<HomeState> emit,
  ) async {
    final driverId = _currentDriverId ?? await _getDriverId();
    if (driverId.isEmpty) return;

    emit(state.copyWith(pendingRequest: null, clearPendingRequest: true));

    // Gui qua WebSocket truoc (low latency)
    if (event.action == 'accept') {
      _webSocketService.sendAccept(event.orderId);
    } else if (event.action == 'decline') {
      _webSocketService.sendDecline(event.orderId);
    }

    try {
      // Goi REST lam backup
      await _orderRepository.respondOrder(event.orderId, event.action);
      await _orderRepository.deleteOrderRequest(driverId, event.requestId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Khong the xu ly yeu cau: $e'));
    }
  }

  void _onWsOrderRequestReceived(
    WsOrderRequestReceived event,
    Emitter<HomeState> emit,
  ) {
    debugPrint('[HomeBloc] WS order request: ${event.orderId}');

    final driverId = _currentDriverId ?? '';

    final orderData = OrderModel(
      id: event.orderId,
      userId: '',
      storeId: '',
      storeName: event.storeName ?? '',
      storeAddress: event.storeAddress,
      items: const [],
      totalAmount: event.totalAmount ?? 0,
      deliveryFee: event.deliveryFee ?? event.estimatedEarning ?? 0,
      estimatedEarning: event.estimatedEarning,
      status: 0,
      deliveryAddress: event.deliveryAddress ?? '',
      paymentMethod: event.paymentMethod ?? 'CASH',
      storeLat: event.storeLat,
      storeLng: event.storeLng,
      deliveryLat: event.deliveryLat,
      deliveryLng: event.deliveryLng,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      receiverName: event.receiverName,
      receiverPhone: event.receiverPhone,
      code: event.orderCode,
      note: event.note,
    );

    final request = OrderRequestModel(
      id: 'ws_${event.orderId}_${DateTime.now().millisecondsSinceEpoch}',
      orderId: event.orderId,
      driverId: driverId,
      status: 0,
      createdAt: DateTime.now(),
      orderData: orderData,
    );

    emit(state.copyWith(
      orderRequests: [request],
      pendingRequest: request,
      clearErrorMessage: true,
    ));
  }

  void _onWsOrderStatusReceived(
    WsOrderStatusReceived event,
    Emitter<HomeState> emit,
  ) {
    debugPrint('[HomeBloc] WS order status: ${event.type} for order ${event.orderId}');

    switch (event.type) {
      case 'ORDER_ACCEPTED':
        emit(state.copyWith(
          orderRequests: const [],
          clearPendingRequest: true,
          errorMessage: event.message ?? 'Ban da nhan don thanh cong.',
        ));
        add(const HomeLoadRequested());
        break;
      case 'ORDER_TAKEN_BY_OTHER':
        emit(state.copyWith(
          orderRequests: const [],
          clearPendingRequest: true,
          errorMessage: event.message ?? 'Don hang da duoc tai xe khac nhan.',
        ));
        break;
      case 'ORDER_CANCELLED':
        emit(state.copyWith(
          orderRequests: const [],
          clearPendingRequest: true,
          errorMessage: event.message ?? 'Don hang da bi huy boi khach hang.',
        ));
        break;
      default:
        break;
    }
  }

  @override
  Future<void> close() {
    _cancelAllSubscriptions();
    _stopLocationUpdates();
    _disconnectWebSocket();
    return super.close();
  }

  Future<void> _connectWebSocket() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.driverTokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('[HomeBloc] No token found for WebSocket connection');
        return;
      }

      _wsOrderRequestSub = _webSocketService.orderRequestStream.listen((notification) {
        if (notification.data != null) {
          add(WsOrderRequestReceived(
            orderId: notification.data!.orderId,
            orderCode: notification.data!.orderCode,
            message: notification.message ?? notification.data!.message,
            storeName: notification.data!.storeName,
            storeAddress: notification.data!.storeAddress,
            storeLat: notification.data!.storeLat,
            storeLng: notification.data!.storeLng,
            deliveryAddress: notification.data!.deliveryAddress,
            receiverName: notification.data!.receiverName,
            receiverPhone: notification.data!.receiverPhone,
            deliveryLat: notification.data!.deliveryLat,
            deliveryLng: notification.data!.deliveryLng,
            deliveryHeading: notification.data!.deliveryHeading,
            deliveryFee: notification.data!.deliveryFee,
            totalAmount: notification.data!.totalAmount,
            finalAmount: notification.data!.finalAmount,
            paymentMethod: notification.data!.paymentMethod,
            note: notification.data!.note,
            estimatedEarning: notification.data!.estimatedEarning,
            expiresAt: notification.data!.expiresAt,
            requestType: notification.data!.requestType,
          ));
        }
      });

      _wsOrderStatusSub = _webSocketService.orderStatusStream.listen((response) {
        if (response.type.isNotEmpty) {
          add(WsOrderStatusReceived(
            type: response.type,
            orderId: response.data,
            message: response.message,
          ));
        }
      });

      if (!_webSocketService.isConnected && !_webSocketService.isConnecting) {
        _webSocketService.connect(token);
      }
      debugPrint('[HomeBloc] WebSocket connected');
    } catch (e) {
      debugPrint('[HomeBloc] WebSocket connection failed: $e');
    }
  }

  void _disconnectWebSocket() {
    _wsOrderRequestSub?.cancel();
    _wsOrderStatusSub?.cancel();
    _wsOrderRequestSub = null;
    _wsOrderStatusSub = null;
    if (_webSocketService.isConnected || _webSocketService.isConnecting) {
      _webSocketService.disconnect();
    }
    debugPrint('[HomeBloc] WebSocket disconnected');
  }

  void sendWsAccept(String orderId) {
    _webSocketService.sendAccept(orderId);
  }

  void sendWsDecline(String orderId) {
    _webSocketService.sendDecline(orderId);
  }
}
