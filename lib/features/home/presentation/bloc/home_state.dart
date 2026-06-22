import 'package:equatable/equatable.dart';
import '../../../../features/orders/domain/entities/order.dart';
import '../../../../features/driver/domain/entities/driver_profile.dart';
import '../../../../features/wallet/domain/entities/wallet.dart';
import '../../../orders/data/models/order_request_model.dart';
import '../../../home/data/repositories/home_repository_impl.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final DriverProfile? driverProfile;
  final bool isOnline;
  final bool isLoadingProfile;
  final List<Order> activeOrders;
  final List<Order> availableOrders;
  final List<Order> recentOrders;
  final TodayStats todayStats;
  final Wallet? wallet;
  final String? errorMessage;
  final String? successMessage;
  final bool isAcceptingOrder;
  final bool isUpdatingStatus;
  final bool isTogglingStatus;
  final bool isUploadingPhoto;
  final bool needsLocationPermission;
  final bool needsReLogin;
  final List<OrderRequestModel> orderRequests;
  final OrderRequestModel? pendingRequest;
  final String? unreadChatMessage;
  final String? currentChatOrderId;

  const HomeState({
    this.status = HomeStatus.initial,
    this.driverProfile,
    this.isOnline = false,
    this.isLoadingProfile = false,
    this.activeOrders = const [],
    this.availableOrders = const [],
    this.recentOrders = const [],
    this.todayStats = const TodayStats(),
    this.wallet,
    this.errorMessage,
    this.successMessage,
    this.isAcceptingOrder = false,
    this.isUpdatingStatus = false,
    this.isTogglingStatus = false,
    this.isUploadingPhoto = false,
    this.needsLocationPermission = false,
    this.needsReLogin = false,
    this.orderRequests = const [],
    this.pendingRequest,
    this.unreadChatMessage,
    this.currentChatOrderId,
  });

  HomeState copyWith({
    HomeStatus? status,
    DriverProfile? driverProfile,
    bool? isOnline,
    bool? isLoadingProfile,
    List<Order>? activeOrders,
    bool clearActiveOrders = false,
    List<Order>? availableOrders,
    List<Order>? recentOrders,
    TodayStats? todayStats,
    Wallet? wallet,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    bool? isAcceptingOrder,
    bool? isUpdatingStatus,
    bool? isTogglingStatus,
    bool? isUploadingPhoto,
    bool? needsLocationPermission,
    bool? needsReLogin,
    List<OrderRequestModel>? orderRequests,
    OrderRequestModel? pendingRequest,
    bool clearPendingRequest = false,
    String? unreadChatMessage,
    bool clearUnreadChatMessage = false,
    String? currentChatOrderId,
  }) {
    return HomeState(
      status: status ?? this.status,
      driverProfile: driverProfile ?? this.driverProfile,
      isOnline: isOnline ?? this.isOnline,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      activeOrders: clearActiveOrders ? [] : (activeOrders ?? this.activeOrders),
      availableOrders: availableOrders ?? this.availableOrders,
      recentOrders: recentOrders ?? this.recentOrders,
      todayStats: todayStats ?? this.todayStats,
      wallet: wallet ?? this.wallet,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      isAcceptingOrder: isAcceptingOrder ?? this.isAcceptingOrder,
      isUpdatingStatus: isUpdatingStatus ?? this.isUpdatingStatus,
      isTogglingStatus: isTogglingStatus ?? this.isTogglingStatus,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      needsLocationPermission: needsLocationPermission ?? this.needsLocationPermission,
      needsReLogin: needsReLogin ?? this.needsReLogin,
      orderRequests: orderRequests ?? this.orderRequests,
      pendingRequest: clearPendingRequest ? null : (pendingRequest ?? this.pendingRequest),
      unreadChatMessage: clearUnreadChatMessage ? null : (unreadChatMessage ?? this.unreadChatMessage),
      currentChatOrderId: currentChatOrderId ?? this.currentChatOrderId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        driverProfile,
        isOnline,
        isLoadingProfile,
        activeOrders,
        availableOrders,
        recentOrders,
        todayStats,
        wallet,
        errorMessage,
        successMessage,
        isAcceptingOrder,
        isUpdatingStatus,
        isTogglingStatus,
        isUploadingPhoto,
        needsLocationPermission,
        needsReLogin,
        orderRequests,
        pendingRequest,
        unreadChatMessage,
        currentChatOrderId,
      ];
}
