import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/forgot_password_bloc.dart';

class ForgotPasswordResetStep extends StatefulWidget {
  final String tempToken;
  final bool isLoading;

  const ForgotPasswordResetStep({
    super.key,
    required this.tempToken,
    required this.isLoading,
  });

  @override
  State<ForgotPasswordResetStep> createState() =>
      _ForgotPasswordResetStepState();
}

class _ForgotPasswordResetStepState extends State<ForgotPasswordResetStep> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.forgotPasswordPasswordRequired;
    }
    if (value.length < 6) {
      return l10n.forgotPasswordPasswordTooShort;
    }
    return null;
  }

  String? _validateConfirm(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.forgotPasswordConfirmRequired;
    }
    if (value != _passwordController.text) {
      return l10n.forgotPasswordConfirmMismatch;
    }
    return null;
  }

  void _onResetPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ForgotPasswordBloc>().add(
            ForgotPasswordResetEvent(
              tempToken: widget.tempToken,
              newPassword: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildIcon(primaryColor),
            const SizedBox(height: 24),
            Text(
              l10n.forgotPasswordStep3Title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.forgotPasswordStep3Subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.onBackgroundDark
                        : AppColors.onBackgroundLight,
                  ),
            ),
            const SizedBox(height: 40),
            _buildPasswordField(isDark, primaryColor, l10n),
            const SizedBox(height: 20),
            _buildConfirmField(isDark, primaryColor, l10n),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _onResetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: primaryColor.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: widget.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      )
                    : Text(
                        l10n.forgotPasswordResetButton,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color primaryColor) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.lock_reset,
        size: 40,
        color: primaryColor,
      ),
    );
  }

  Widget _buildPasswordField(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
      decoration: InputDecoration(
        labelText: l10n.forgotPasswordNewPasswordLabel,
        hintText: l10n.forgotPasswordNewPasswordHint,
        prefixIcon: Icon(Icons.lock_outlined, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: primaryColor,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        labelStyle: TextStyle(
          color:
              isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.5)
            : AppColors.surfaceLight.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorDark : AppColors.errorLight,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      validator: (value) => _validatePassword(value, l10n),
    );
  }

  Widget _buildConfirmField(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return TextFormField(
      controller: _confirmController,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onResetPassword(),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
      decoration: InputDecoration(
        labelText: l10n.forgotPasswordConfirmPasswordLabel,
        hintText: l10n.forgotPasswordConfirmPasswordHint,
        prefixIcon: Icon(Icons.lock_outlined, color: primaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: primaryColor,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        labelStyle: TextStyle(
          color:
              isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
        ),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.5)
            : AppColors.surfaceLight.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.errorDark : AppColors.errorLight,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      validator: (value) => _validateConfirm(value, l10n),
    );
  }
}
