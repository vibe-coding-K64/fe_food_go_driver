import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'features/core/presentation/bloc/theme/theme_bloc.dart';
import 'features/core/presentation/bloc/locale/locale_bloc.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase_impl.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/bloc/register_bloc.dart';
import 'features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'features/driver/data/datasources/driver_remote_datasource.dart';
import 'features/driver/data/repositories/driver_repository_impl.dart';
import 'features/driver/domain/repositories/driver_repository.dart';
import 'features/orders/data/datasources/order_remote_datasource.dart';
import 'features/orders/data/repositories/order_repository_impl.dart';
import 'features/orders/domain/repositories/order_repository.dart';
import 'features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'features/wallet/data/repositories/wallet_repository_impl.dart';
import 'features/wallet/domain/repositories/wallet_repository.dart';
import 'features/home/data/datasources/home_remote_datasource.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/chat/data/datasources/chat_remote_datasource.dart';
import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'core/constants/app_constants.dart';
import 'services/driver_realtime_service.dart';
import 'services/chat_realtime_service.dart';

final getIt = GetIt.instance;

Future<String> _getTokenFromStorage() async {
  try {
    final secureStorage = getIt<FlutterSecureStorage>();
    final token = await secureStorage.read(key: AppConstants.driverTokenKey);
    return token ?? '';
  } catch (_) {
    return '';
  }
}

Future<void> init() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);

  // Driver Realtime Service (WebSocket)
  getIt.registerLazySingleton<DriverRealtimeService>(
    () => DriverRealtimeService(secureStorage: getIt<FlutterSecureStorage>()),
  );

  // HTTP Client
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Chat Realtime Service (WebSocket)
  getIt.registerLazySingleton<ChatRealtimeService>(
    () => ChatRealtimeService(secureStorage: getIt<FlutterSecureStorage>()),
  );

  // Chat data source (HTTP)
  getIt.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSource(
      httpClient: getIt<http.Client>(),
      baseApiUrl: AppConstants.baseApiUrl,
      getToken: _getTokenFromStorage,
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  // Chat repository
  getIt.registerLazySingleton<ChatRepository>(
    () => ChatRepository(getIt<ChatRemoteDataSource>()),
  );

  // Chat BLoC singleton
  getIt.registerLazySingleton<ChatBloc>(
    () => ChatBloc(
      chatRepository: getIt<ChatRepository>(),
      realtimeService: getIt<DriverRealtimeService>(),
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  // Auth data source
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(
      httpClient: getIt<http.Client>(),
      baseApiUrl: AppConstants.baseApiUrl,
    ),
  );

  // Auth repository
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: getIt<AuthRemoteDataSource>(),
    secureStorage: getIt<FlutterSecureStorage>(),
  );
  getIt.registerSingleton<AuthRepository>(authRepository);

  // Driver data source (HTTP)
  getIt.registerLazySingleton<DriverRemoteDataSource>(
    () => DriverRemoteDataSource(
      httpClient: getIt<http.Client>(),
      baseApiUrl: AppConstants.baseApiUrl,
      getToken: _getTokenFromStorage,
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  // Driver repository
  getIt.registerLazySingleton<DriverRepository>(
    () => DriverRepositoryImpl(getIt<DriverRemoteDataSource>()),
  );

  // Order data source (HTTP)
  getIt.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSource(
      httpClient: getIt<http.Client>(),
      baseApiUrl: AppConstants.baseApiUrl,
      getToken: _getTokenFromStorage,
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  // Order repository
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(getIt<OrderRemoteDataSource>()),
  );

  // Wallet data source (HTTP)
  getIt.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSource(
      httpClient: getIt<http.Client>(),
      baseApiUrl: AppConstants.baseApiUrl,
      getToken: _getTokenFromStorage,
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  // Wallet repository
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(
      getIt<WalletRemoteDataSource>(),
      getIt<FlutterSecureStorage>(),
    ),
  );

  // Home data source (HTTP)
  getIt.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSource(
      httpClient: getIt<http.Client>(),
      baseApiUrl: AppConstants.baseApiUrl,
      getToken: _getTokenFromStorage,
      secureStorage: getIt<FlutterSecureStorage>(),
    ),
  );

  // Home repository
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepository(
      homeRemote: getIt<HomeRemoteDataSource>(),
      driverRemote: getIt<DriverRemoteDataSource>(),
      walletRemote: getIt<WalletRemoteDataSource>(),
    ),
  );

  // Use cases
  getIt.registerFactory<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>().login),
  );

  getIt.registerFactory<LogoutUseCaseImpl>(
    () => LogoutUseCaseImpl(getIt<AuthRepository>()),
  );

  // BLoCs
  getIt.registerFactory<ThemeBloc>(
    () => ThemeBloc(sharedPreferences: getIt<SharedPreferences>()),
  );

  getIt.registerFactory<LocaleBloc>(
    () => LocaleBloc(sharedPreferences: getIt<SharedPreferences>()),
  );

  getIt.registerFactory<LoginBloc>(
    () => LoginBloc(
      authRepository: getIt<AuthRepository>(),
      loginUseCase: getIt<LoginUseCase>(),
    ),
  );

  getIt.registerFactory<RegisterBloc>(
    () => RegisterBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<ForgotPasswordBloc>(
    () => ForgotPasswordBloc(authRepository: getIt<AuthRepository>()),
  );

  getIt.registerFactory<HomeBloc>(
    () => HomeBloc(
      homeRepository: getIt<HomeRepository>(),
      driverRepository: getIt<DriverRepository>(),
      orderRepository: getIt<OrderRepository>(),
      secureStorage: getIt<FlutterSecureStorage>(),
      driverRealtimeService: getIt<DriverRealtimeService>(),
    ),
  );
}

Locale getDeviceLocale() {
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  if (deviceLocale.languageCode == 'vi') {
    return const Locale('vi');
  }
  return const Locale('en');
}
