import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class OtpBottomSheet extends StatefulWidget {
  final String email;
  final bool isVerifying;
  final bool isResending;
  final void Function(String otp) onVerify;
  final VoidCallback onResend;
  final VoidCallback onClose;

  const OtpBottomSheet({
    super.key,
    required this.email,
    required this.isVerifying,
    required this.isResending,
    required this.onVerify,
    required this.onResend,
    required this.onClose,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onPinCompleted(String value) {
    if (value.length == 6) {
      widget.onVerify(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final onSurfaceColor =
        isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;
    final errorColor =
        isDark ? AppColors.errorDark : AppColors.errorLight;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.outlineDark
                            : AppColors.outlineLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 30,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.otpVerificationTitle,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.otpEmailSent(widget.email),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.onBackgroundDark
                                    : AppColors.onBackgroundLight,
                              ),
                    ),
                    const SizedBox(height: 24),
                    Pinput(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      length: 6,
                      enabled: !widget.isVerifying,
                      onChanged: (value) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                      onCompleted: _onPinCompleted,
                      defaultPinTheme: PinTheme(
                        width: 48,
                        height: 56,
                        textStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceColor,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.outlineDark
                                : AppColors.outlineLight,
                            width: 2,
                          ),
                        ),
                      ),
                      focusedPinTheme: PinTheme(
                        width: 48,
                        height: 56,
                        textStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor,
                            width: 2.5,
                          ),
                        ),
                      ),
                      errorPinTheme: PinTheme(
                        width: 48,
                        height: 56,
                        textStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: errorColor,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: errorColor,
                            width: 2.5,
                          ),
                        ),
                      ),
                      cursor: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 2,
                            height: 20,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      keyboardType: TextInputType.number,
                      showCursor: true,
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: TextStyle(
                          color: errorColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: widget.isVerifying
                            ? null
                            : () {
                                final code = _pinController.text.trim();
                                if (code.length != 6) {
                                  setState(() {
                                    _errorText = l10n.otpEnterFullCode;
                                  });
                                  return;
                                }
                                widget.onVerify(code);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor:
                              isDark ? Colors.black : Colors.white,
                          disabledBackgroundColor:
                              primaryColor.withValues(alpha: 0.5),
                          disabledForegroundColor:
                              (isDark ? Colors.black : Colors.white)
                                  .withValues(alpha: 0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: widget.isVerifying
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              )
                            : Text(
                                l10n.otpVerifyButton,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.otpNoReceive,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.onBackgroundDark
                                : AppColors.onBackgroundLight,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              widget.isResending ? null : widget.onResend,
                          child: widget.isResending
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryColor,
                                  ),
                                )
                              : Text(
                                  l10n.otpResendButton,
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: widget.onClose,
                      child: Text(
                        l10n.otpChangeEmail,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.onBackgroundDark
                              : AppColors.onBackgroundLight,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
