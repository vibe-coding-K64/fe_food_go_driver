import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import 'register_page_wrapper.dart';
import 'forgot_password_page_wrapper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginBloc>().add(
            LoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (prev, curr) => curr is LoginSuccess,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
          navigator.pushNamedAndRemoveUntil('/', (route) => false);
        });
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLogo(isDark),
                    const SizedBox(height: 8),
                    Text(
                      l10n.welcomeDriver,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: isDark
                                ? AppColors.onSurfaceDark
                                : AppColors.onBackgroundLight,
                          ),
                    ),
                    const SizedBox(height: 40),
                    _buildEmailField(isDark, l10n),
                    const SizedBox(height: 16),
                    _buildPasswordField(isDark, l10n),
                    const SizedBox(height: 8),
                    _buildForgotPassword(isDark, l10n),
                    const SizedBox(height: 24),
                    _buildLoginButton(l10n, context.watch<LoginBloc>().state),
                    const SizedBox(height: 24),
                    _buildRegisterPrompt(l10n),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Image.asset(
      'assets/img/logo.png',
      width: 100,
      height: 100,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.delivery_dining,
        size: 56,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmailField(bool isDark, AppLocalizations l10n) {
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
      decoration: InputDecoration(
        labelText: l10n.emailLabel,
        prefixIcon: Icon(Icons.email_outlined, color: primaryColor),
        labelStyle: TextStyle(
          color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
        ),
        hintText: 'driver@example.com',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.emailRequired;
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
        if (!emailRegex.hasMatch(value.trim())) {
          return l10n.invalidEmail;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(bool isDark, AppLocalizations l10n) {
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onLoginPressed(),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
      decoration: InputDecoration(
        labelText: l10n.passwordLabel,
        prefixIcon: Icon(Icons.lock_outlined, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: primaryColor,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.passwordRequired;
        }
        if (value.length < 6) {
          return l10n.passwordTooShort;
        }
        return null;
      },
    );
  }

  Widget _buildForgotPassword(bool isDark, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ForgotPasswordPageWrapper(),
            ),
          );
        },
        child: Text(
          l10n.forgotPassword,
          style: TextStyle(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AppLocalizations l10n, LoginState state) {
    final isLoading = state is LoginLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

        return SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _onLoginPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
              disabledForegroundColor: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: 0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  )
                : Text(
                    l10n.loginButton,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
  }

  Widget _buildRegisterPrompt(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.registerPrompt,
          style: TextStyle(
            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RegisterPageWrapper(),
              ),
            );
          },
          child: Text(
            l10n.registerLink,
            style: TextStyle(
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
