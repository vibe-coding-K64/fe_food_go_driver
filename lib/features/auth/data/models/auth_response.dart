import '../../domain/entities/auth_response.dart';
import '../../domain/entities/auth_user.dart';

class AuthResponseModel extends AuthResponse {
  const AuthResponseModel({
    required super.token,
    required super.refreshToken,
    required super.expiresIn,
    required super.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final userId = userJson['id'] ?? userJson['userId'] ?? userJson['_id'];

    return AuthResponseModel(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: AuthUser(
        id: userId?.toString() ?? '',
        email: userJson['email'] as String? ?? '',
        fullName: userJson['fullName'] as String?,
        phoneNumber: userJson['phoneNumber'] as String?,
        photoUrl: userJson['photoUrl'] as String?,
      ),
    );
  }
}
