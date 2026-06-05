import '../../domain/entities/forgot_reset_response.dart';

class ForgotResetResponseModel extends ForgotResetResponse {
  const ForgotResetResponseModel({required super.message});

  factory ForgotResetResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotResetResponseModel(
      message: json['message'] as String? ?? 'Password reset successfully',
    );
  }
}
