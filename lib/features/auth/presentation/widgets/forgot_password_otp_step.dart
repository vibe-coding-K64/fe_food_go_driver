import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/forgot_password_bloc.dart';

class ForgotPasswordOtpStep extends StatefulWidget {
  final String emailOrPhone;
  final bool isLoading;
  final int countdownSeconds;
  final bool canResend;
  final VoidCallback onResend;

  const ForgotPasswordOtpStep({
    super.key,
    required this.emailOrPhone,
    required this.isLoading,
    required this.countdownSeconds,
    required this.canResend,
    required this.onResend,
  });

  @override
  State<ForgotPasswordOtpStep> createState() => _ForgotPasswordOtpStepState();
}

class _ForgotPasswordOtpStepState extends State<ForgotPasswordOtpStep> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _hasError = false;
  int _localSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _localSeconds = widget.countdownSeconds;
    _startTimer();
  }

  @override
  void didUpdateWidget(ForgotPasswordOtpStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countdownSeconds != widget.countdownSeconds) {
      _stopTimer();
      _localSeconds = widget.countdownSeconds;
      _startTimer();
    }
  }

  void _startTimer() {
    if (_localSeconds > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (_localSeconds > 0) {
            _localSeconds--;
          } else {
            _timer?.cancel();
          }
        });
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  void _onOtpChanged(String value, int index) {
    if (_hasError) {
      setState(() => _hasError = false);
    }
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_controllers.every((c) => c.text.isNotEmpty)) {
      _verifyOtp();
    }
  }

  void _verifyOtp() {
    if (_otpCode.length < 6) return;
    context.read<ForgotPasswordBloc>().add(
          ForgotPasswordVerifyOtpEvent(
            emailOrPhone: widget.emailOrPhone,
            otpCode: _otpCode,
          ),
        );
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final l10n = AppLocalizations.of(context)!;
    final isExpired = _localSeconds == 0;
    final canResend = widget.canResend || isExpired;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          _buildIcon(primaryColor),
          const SizedBox(height: 24),
          Text(
            l10n.forgotPasswordStep2Title,
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
            l10n.forgotPasswordStep2Subtitle(widget.emailOrPhone),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? AppColors.onBackgroundDark
                      : AppColors.onBackgroundLight,
                ),
          ),
          const SizedBox(height: 16),
          _buildCountdown(isDark, primaryColor, isExpired),
          const SizedBox(height: 32),
          _buildOtpInputs(isDark, primaryColor),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: widget.isLoading || _otpCode.length < 6
                  ? null
                  : _verifyOtp,
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
                      l10n.forgotPasswordVerifyOtp,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _buildResendRow(l10n, isDark, primaryColor, canResend),
          const SizedBox(height: 32),
        ],
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
        Icons.sms_outlined,
        size: 40,
        color: primaryColor,
      ),
    );
  }

  Widget _buildCountdown(bool isDark, Color primaryColor, bool isExpired) {
    final color = isExpired
        ? (isDark ? AppColors.errorDark : AppColors.errorLight)
        : primaryColor;
    final countdownValue = _formatCountdown(_localSeconds);
    final countdownText = isExpired
        ? 'Hết hạn'
        : '${AppLocalizations.of(context)!.forgotPasswordCountdown} $countdownValue';
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(Icons.timer_outlined, color: color, size: 20),
            ),
            const WidgetSpan(child: SizedBox(width: 6)),
            TextSpan(text: countdownText, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpInputs(bool isDark, Color primaryColor) {
    final borderColor = _hasError
        ? (isDark ? AppColors.errorDark : AppColors.errorLight)
        : (isDark ? AppColors.outlineDark : AppColors.outlineLight);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AspectRatio(
              aspectRatio: 0.75,
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: isDark
                          ? AppColors.onSurfaceDark
                          : AppColors.onSurfaceLight,
                      fontWeight: FontWeight.bold,
                    ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark.withValues(alpha: 0.5)
                      : AppColors.surfaceLight.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                onChanged: (value) => _onOtpChanged(value, index),
                onFieldSubmitted: (_) => _verifyOtp(),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendRow(AppLocalizations l10n, bool isDark, Color primaryColor, bool canResend) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          l10n.forgotPasswordNoReceive,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
        ),
        TextButton(
          onPressed: canResend
              ? () {
                  _clearOtp();
                  widget.onResend();
                }
              : null,
          child: Text(
            l10n.forgotPasswordResend,
            style: TextStyle(
              color: canResend
                  ? primaryColor
                  : (isDark ? AppColors.outlineDark : AppColors.outlineLight),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
