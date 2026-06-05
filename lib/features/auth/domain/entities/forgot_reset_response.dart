import 'package:equatable/equatable.dart';

class ForgotResetResponse extends Equatable {
  final String message;

  const ForgotResetResponse({required this.message});

  @override
  List<Object?> get props => [message];
}
