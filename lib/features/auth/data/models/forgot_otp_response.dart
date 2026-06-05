import '../../domain/entities/forgot_otp_response.dart';

class ForgotOtpResponseModel extends ForgotOtpResponse {
  const ForgotOtpResponseModel({
    required super.emailOrPhone,
    required super.message,
    required super.expiresInSeconds,
  });

  factory ForgotOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotOtpResponseModel(
      emailOrPhone: json['emailOrPhone'] as String? ??
                    json['email'] as String? ??
                    json['phone'] as String? ??
                    '',
      message: json['message'] as String? ?? 'OTP sent successfully',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ??
                        (json['expiresIn'] as num?)?.toInt() ??
                        300,
    );
  }
}
