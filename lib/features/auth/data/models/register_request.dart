class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      };
}
