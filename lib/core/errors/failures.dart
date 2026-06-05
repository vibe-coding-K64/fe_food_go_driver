import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication error occurred']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Validation error occurred']);
}

class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure([super.message = 'Location service is disabled. Please enable it to use online features.']);
}

class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure([super.message = 'Location permission is required to go online. Please allow location access.']);
}

class LocationServiceUnavailableFailure extends Failure {
  const LocationServiceUnavailableFailure([super.message = 'Location service is unavailable. Please enable GPS.']);
}
