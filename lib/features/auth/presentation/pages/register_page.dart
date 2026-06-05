import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/register_bloc.dart';
import '../bloc/register_event.dart';
import '../bloc/register_state.dart';
import '../widgets/otp_bottom_sheet.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.registerFullNameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.registerFullNameTooShort;
    }
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.emailRequired;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.invalidEmail;
    }
    return null;
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.registerPhoneRequired;
    }
    final phoneRegex = RegExp(r'^0[3|5|7|8|9][0-9]{8}$');
    if (!phoneRegex.hasMatch(value.trim().replaceAll(RegExp(r'[\s\-()]'), ''))) {
      return l10n.registerInvalidPhone;
    }
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 8) {
      return l10n.registerPasswordTooShort;
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return l10n.registerPasswordNeedUppercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return l10n.registerPasswordNeedNumber;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.registerConfirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return l10n.registerConfirmPasswordMismatch;
    }
    return null;
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<RegisterBloc>().add(
            RegisterFormSubmitted(
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              fullName: _fullNameController.text.trim(),
            ),
          );
    }
  }

  void _showOtpSheet(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
        builder: (ctx) => BlocProvider.value(
        value: context.read<RegisterBloc>(),
        child: BlocBuilder<RegisterBloc, RegisterState>(
          builder: (ctx, state) {
            return BlocListener<RegisterBloc, RegisterState>(
              listener: (ctx, state) {
                if (state is RegisterSuccess) {
                  Navigator.of(ctx).pop();
                } else if (state is OtpFailure) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor:
                          Theme.of(ctx).brightness == Brightness.dark
                              ? AppColors.errorDark
                              : AppColors.errorLight,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: OtpBottomSheet(
                email: email,
                isVerifying: state is OtpVerifying,
                isResending: state is OtpResending,
                onVerify: (otp) {
                  context.read<RegisterBloc>().add(
                        OtpSubmitted(email: email, otpCode: otp),
                      );
                },
                onResend: () {
                  context.read<RegisterBloc>().add(
                        OtpResendRequested(
                          email: _emailController.text.trim(),
                          phoneNumber: _phoneController.text.trim(),
                          password: _passwordController.text,
                          fullName: _fullNameController.text.trim(),
                        ),
                      );
                },
                onClose: () {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(ctx).pop();
                    context.read<RegisterBloc>().add(const RegisterReset());
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _onBackToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: primaryColor,
            size: 28,
          ),
          onPressed: _onBackToLogin,
          tooltip: l10n.back,
        ),
        title: Text(
          l10n.registerTitle,
          style: TextStyle(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (ctx, state) {
          if (state is OtpSent) {
            _showOtpSheet(state.email);
          } else if (state is RegisterSuccess &&
              (state.user.id?.isNotEmpty ?? false)) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dang ky thanh cong!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
            });
          } else if (state is RegisterFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: isDark
                    ? AppColors.errorDark
                    : AppColors.errorLight,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            context.read<RegisterBloc>().add(const RegisterReset());
          }
        },
        builder: (ctx, state) {
          final isLoading = state is RegisterLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderSection(isDark, l10n),
                      const SizedBox(height: 32),
                      _buildFullNameField(isDark, l10n),
                      const SizedBox(height: 16),
                      _buildEmailField(isDark, l10n),
                      const SizedBox(height: 16),
                      _buildPhoneField(isDark, l10n),
                      const SizedBox(height: 16),
                      _buildPasswordField(isDark, l10n),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(isDark, l10n),
                      const SizedBox(height: 8),
                      _buildPasswordStrengthIndicator(l10n),
                      const SizedBox(height: 32),
                      _buildRegisterButton(isDark, isLoading, l10n),
                      const SizedBox(height: 24),
                      _buildLoginPrompt(isDark, l10n),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (isLoading) _buildLoadingOverlay(isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark, AppLocalizations l10n) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delivery_dining,
            size: 44,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.registerSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
        ),
      ],
    );
  }

  Widget _buildFullNameField(bool isDark, AppLocalizations l10n) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _buildTextField(
      controller: _fullNameController,
      label: l10n.registerFullNameLabel,
      hint: l10n.registerFullNameHint,
      prefixIcon: Icons.person_outline_rounded,
      primaryColor: primaryColor,
      isDark: isDark,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: (v) => _validateFullName(v, l10n),
      textInputType: TextInputType.name,
    );
  }

  Widget _buildEmailField(bool isDark, AppLocalizations l10n) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _buildTextField(
      controller: _emailController,
      label: l10n.emailLabel,
      hint: 'driver@example.com',
      prefixIcon: Icons.email_outlined,
      primaryColor: primaryColor,
      isDark: isDark,
      textInputAction: TextInputAction.next,
      validator: (v) => _validateEmail(v, l10n),
      textInputType: TextInputType.emailAddress,
      autocorrect: false,
    );
  }

  Widget _buildPhoneField(bool isDark, AppLocalizations l10n) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _buildTextField(
      controller: _phoneController,
      label: l10n.registerPhoneLabel,
      hint: l10n.registerPhoneHint,
      prefixIcon: Icons.phone_android_outlined,
      primaryColor: primaryColor,
      isDark: isDark,
      textInputAction: TextInputAction.next,
      validator: (v) => _validatePhone(v, l10n),
      textInputType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\s\-()]')),
        LengthLimitingTextInputFormatter(12),
      ],
    );
  }

  Widget _buildPasswordField(bool isDark, AppLocalizations l10n) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _buildTextField(
      controller: _passwordController,
      label: l10n.passwordLabel,
      hint: l10n.registerPasswordHint,
      prefixIcon: Icons.lock_outline_rounded,
      primaryColor: primaryColor,
      isDark: isDark,
      textInputAction: TextInputAction.next,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          color: primaryColor,
          size: 24,
        ),
        onPressed: () {
          setState(() => _obscurePassword = !_obscurePassword);
        },
      ),
      validator: (v) => _validatePassword(v, l10n),
      textInputType: TextInputType.visiblePassword,
    );
  }

  Widget _buildConfirmPasswordField(bool isDark, AppLocalizations l10n) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return _buildTextField(
      controller: _confirmPasswordController,
      label: l10n.registerConfirmPasswordLabel,
      hint: l10n.registerConfirmPasswordHint,
      prefixIcon: Icons.lock_outline_rounded,
      primaryColor: primaryColor,
      isDark: isDark,
      textInputAction: TextInputAction.done,
      obscureText: _obscureConfirmPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          color: primaryColor,
          size: 24,
        ),
        onPressed: () {
          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
        },
      ),
      validator: (v) => _validateConfirmPassword(v, l10n),
      textInputType: TextInputType.visiblePassword,
    );
  }

  Widget _buildPasswordStrengthIndicator(AppLocalizations l10n) {
    final password = _passwordController.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.registerPasswordStrength,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
        ),
        const SizedBox(height: 6),
        _strengthBar(l10n.registerPasswordMinChars, hasLength, isDark),
        const SizedBox(height: 4),
        _strengthBar(l10n.registerPasswordUppercase, hasUppercase, isDark),
        const SizedBox(height: 4),
        _strengthBar(l10n.registerPasswordNumber, hasNumber, isDark),
      ],
    );
  }

  Widget _strengthBar(String label, bool passed, bool isDark) {
    final color = passed
        ? AppColors.success
        : (isDark ? AppColors.outlineDark : AppColors.outlineLight);
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: passed ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required Color primaryColor,
    required bool isDark,
    required TextInputAction textInputAction,
    String? Function(String?)? validator,
    TextInputType? textInputType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool autocorrect = true,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      keyboardType: textInputType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      autocorrect: autocorrect,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            fontSize: 17,
          ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: isDark
              ? AppColors.onBackgroundDark
              : AppColors.onBackgroundLight,
          fontSize: 16,
        ),
        prefixIcon: Icon(prefixIcon, color: primaryColor, size: 24),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E1E) : AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorDark : AppColors.errorLight,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorDark : AppColors.errorLight,
            width: 2.5,
          ),
        ),
        errorStyle: TextStyle(
          color: isDark ? AppColors.errorDark : AppColors.errorLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRegisterButton(
      bool isDark, bool isLoading, AppLocalizations l10n) {
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : _onRegisterPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
          disabledForegroundColor:
              (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
          shadowColor: primaryColor.withValues(alpha: 0.4),
        ),
        child: isLoading
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.how_to_reg_rounded, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    l10n.registerButton,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginPrompt(bool isDark, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.registerPrompt,
          style: TextStyle(
            color: isDark
                ? AppColors.onBackgroundDark
                : AppColors.onBackgroundLight,
            fontSize: 15,
          ),
        ),
        TextButton(
          onPressed: _onBackToLogin,
          child: Text(
            l10n.loginButton,
            style: TextStyle(
              color: isDark
                  ? AppColors.primaryDark
                  : AppColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(bool isDark) {
    return Container(
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: isDark
                      ? AppColors.primaryDark
                      : AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.registerSendingOtp,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? AppColors.onSurfaceDark
                          : AppColors.onSurfaceLight,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
