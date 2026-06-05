import '../../domain/entities/forgot_verify_response.dart';

class ForgotVerifyResponseModel extends ForgotVerifyResponse {
  const ForgotVerifyResponseModel({
    required super.tempToken,
    required super.expiresIn,
    required super.message,
  });

  factory ForgotVerifyResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotVerifyResponseModel(
      tempToken: json['tempToken'] as String? ?? json['token'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ??
                 (json['expiresInSeconds'] as num?)?.toInt() ??
                 300,
      message: json['message'] as String? ?? 'OTP verified successfully',
    );
  }
}
