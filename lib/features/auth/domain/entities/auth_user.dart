import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  final String? id;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? photoUrl;

  const AuthUser({
    this.id,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.photoUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString(),
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, email, fullName, phoneNumber, photoUrl];
}
