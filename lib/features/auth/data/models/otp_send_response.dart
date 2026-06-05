import '../../domain/entities/otp_send_response.dart';

class OtpSendResponseModel extends OtpSendResponse {
  const OtpSendResponseModel({
    required super.emailOrPhone,
    required super.otpCode,
    required super.expiresInSeconds,
    required super.message,
  });

  factory OtpSendResponseModel.fromJson(Map<String, dynamic> json) {
    return OtpSendResponseModel(
      emailOrPhone: json['emailOrPhone'] as String? ?? json['email'] as String? ?? '',
      otpCode: json['otpCode'] as String? ?? '',
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 300,
      message: json['message'] as String? ?? 'OTP sent successfully',
    );
  }
}
