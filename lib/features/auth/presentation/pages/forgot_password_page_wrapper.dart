import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/forgot_password_bloc.dart';
import 'forgot_password_page.dart';

class ForgotPasswordPageWrapper extends StatelessWidget {
  const ForgotPasswordPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordBloc>(
      create: (_) => ForgotPasswordBloc(
        authRepository: GetIt.instance<AuthRepository>(),
      ),
      child: const ForgotPasswordPage(),
    );
  }
}
