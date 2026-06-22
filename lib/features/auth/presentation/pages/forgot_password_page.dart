import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/forgot_password_bloc.dart';
import '../widgets/forgot_password_email_step.dart';
import '../widgets/forgot_password_otp_step.dart';
import '../widgets/forgot_password_reset_step.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showSuccessDialog(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 64,
        ),
        title: Text(
          l10n.forgotPasswordSuccessTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Text(
          l10n.forgotPasswordSuccessMessage,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.primaryDark : AppColors.primaryLight,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.forgotPasswordGoToLogin,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.forgotPasswordTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (ctx, state) {
          if (state is ForgotPasswordError) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: isDark ? AppColors.errorDark : AppColors.errorLight,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.errorTitle),
                  ],
                ),
                content: Text(state.message),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.errorDark
                          : AppColors.errorLight,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.close),
                  ),
                ],
              ),
            );
          }

          if (state is ForgotPasswordOtpSent) {
            _animateToPage(1);
          }

          if (state is ForgotPasswordOtpVerified) {
            _animateToPage(2);
          }

          if (state is ForgotPasswordResetSuccess) {
            _showSuccessDialog(context, l10n);
          }
        },
        builder: (context, state) {
          final currentPage = _getPageIndex(state.currentStep);
          return Column(
            children: [
              _buildStepIndicator(context, currentPage, l10n),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ForgotPasswordEmailStep(
                      isLoading: state is ForgotPasswordLoading &&
                          state.currentStep == ForgotPasswordStep.inputEmail,
                    ),
                    ForgotPasswordOtpStep(
                      emailOrPhone: state.emailOrPhone,
                      isLoading: state is ForgotPasswordLoading &&
                          state.currentStep == ForgotPasswordStep.inputOtp,
                      countdownSeconds: state.countdownSeconds,
                      canResend: state.canResend,
                      onResend: () {
                        context.read<ForgotPasswordBloc>().add(
                              ForgotPasswordResendOtpEvent(
                                emailOrPhone: state.emailOrPhone,
                              ),
                            );
                      },
                    ),
                    ForgotPasswordResetStep(
                      tempToken: state.tempToken ?? '',
                      isLoading: state is ForgotPasswordLoading &&
                          state.currentStep ==
                              ForgotPasswordStep.inputNewPassword,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _getPageIndex(ForgotPasswordStep step) {
    switch (step) {
      case ForgotPasswordStep.inputEmail:
        return 0;
      case ForgotPasswordStep.inputOtp:
        return 1;
      case ForgotPasswordStep.inputNewPassword:
        return 2;
    }
  }

  Widget _buildStepIndicator(
    BuildContext context,
    int currentPage,
    AppLocalizations l10n,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor = isDark ? AppColors.outlineDark : AppColors.outlineLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _buildStepDot(0, currentPage, primaryColor, inactiveColor),
          Expanded(child: _buildStepLine(0, currentPage, primaryColor, inactiveColor)),
          _buildStepDot(1, currentPage, primaryColor, inactiveColor),
          Expanded(child: _buildStepLine(1, currentPage, primaryColor, inactiveColor)),
          _buildStepDot(2, currentPage, primaryColor, inactiveColor),
        ],
      ),
    );
  }

  Widget _buildStepDot(
    int index,
    int currentPage,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isActive = index <= currentPage;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.3),
        border: Border.all(
          color: isActive ? activeColor : inactiveColor,
          width: 2,
        ),
      ),
      child: Center(
        child: isActive && index < currentPage
            ? const Icon(Icons.check, color: Colors.white, size: 14)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : inactiveColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
      ),
    );
  }

  Widget _buildStepLine(
    int lineIndex,
    int currentPage,
    Color activeColor,
    Color inactiveColor,
  ) {
    final isActive = lineIndex < currentPage;
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.3),
      ),
    );
  }
}
