import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../wallet/presentation/bloc/wallet_bloc.dart';
import '../../../wallet/presentation/bloc/wallet_event.dart';
import '../../../wallet/presentation/bloc/wallet_state.dart';

class WithdrawScreen extends StatefulWidget {
  final double balance;

  const WithdrawScreen({super.key, required this.balance});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int? _selectedAmount;

  final List<int> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int _parseDigits(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'\D'), '')) ?? 0;
  }

  void _selectQuickAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = _formatInput(amount.toString());
    });
  }

  void _selectAll() {
    final all = widget.balance.floor();
    setState(() {
      _selectedAmount = null;
      _amountController.text = _formatInput(all.toString());
    });
  }

  String? _validateAmount(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final amount = _parseDigits(value ?? '');
    if (amount < 50000) return l10n.minWithdraw;
    if (amount > widget.balance) return l10n.insufficientBalance;
    return null;
  }

  void _submitWithdraw() {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    final amount = _parseDigits(_amountController.text).toDouble();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmWithdraw),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.withdrawAmount}: ${_formatInput(amount.toInt().toString())} VND'),
            Text('${l10n.withdrawFee}: 0 VND'),
            const Divider(),
            Text(
              '${l10n.netAmount}: ${_formatInput(amount.toInt().toString())} VND',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<WalletBloc>().add(WithdrawRequested(amount));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirmWithdraw),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state.withdrawStatus == WithdrawStatus.success) {
          Navigator.of(context).pop();
        }
        if (state.withdrawStatus == WithdrawStatus.error &&
            state.withdrawErrorMessage != null) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorLight, size: 24),
                  SizedBox(width: 8),
                  Text(l10n.errorTitle),
                ],
              ),
              content: Text(state.withdrawErrorMessage!),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorLight,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.close),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.withdraw),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceDisplay(isDark, primaryColor, l10n),
                  const SizedBox(height: 24),
                  _buildAmountInput(isDark, primaryColor, l10n),
                  const SizedBox(height: 16),
                  _buildQuickAmountChips(isDark, primaryColor, l10n),
                  const SizedBox(height: 24),
                  _buildBankInfo(isDark, primaryColor, l10n),
                  const SizedBox(height: 24),
                  _buildWithdrawDetail(isDark, primaryColor, l10n),
                  const SizedBox(height: 24),
                  _buildSubmitButton(state, primaryColor, l10n),
                  const SizedBox(height: 16),
                  _buildNote(isDark, l10n),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceDisplay(
      bool isDark, Color primaryColor, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.balanceAvailable,
              style: TextStyle(
                color:
                    isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
              ),
            ),
            Text(
              '${_formatInput(widget.balance.toInt().toString())} VND',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(
      bool isDark, Color primaryColor, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.withdrawAmount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '0',
            prefixText: '',
            suffixText: 'VND',
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: isDark ? AppColors.outlineDark : AppColors.outlineLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
          validator: _validateAmount,
          onChanged: (value) {
            setState(() => _selectedAmount = null);
          },
        ),
      ],
    );
  }

  Widget _buildQuickAmountChips(
      bool isDark, Color primaryColor, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._quickAmounts.map((amount) {
          final isSelected = _selectedAmount == amount;
          return ChoiceChip(
            label: Text('${_formatInput(amount.toString())}'),
            selected: isSelected,
            onSelected: (_) => _selectQuickAmount(amount),
            selectedColor: primaryColor.withValues(alpha: 0.2),
            labelStyle: TextStyle(
              color: isSelected
                  ? primaryColor
                  : (isDark
                      ? AppColors.onBackgroundDark
                      : AppColors.onBackgroundLight),
            ),
          );
        }),
        ChoiceChip(
          label: Text(l10n.allTransactions),
          selected: _selectedAmount == null &&
              _parseDigits(_amountController.text) == widget.balance.toInt(),
          onSelected: (_) => _selectAll(),
          selectedColor: primaryColor.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget _buildBankInfo(
      bool isDark, Color primaryColor, AppLocalizations l10n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  l10n.bankInfo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.onSurfaceDark
                        : AppColors.onSurfaceLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Vietcombank',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.onSurfaceDark
                    : AppColors.onSurfaceLight,
              ),
            ),
            Text(
              '••••••1234',
              style: TextStyle(
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
            Text(
              'NGUYEN VAN A',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawDetail(
      bool isDark, Color primaryColor, AppLocalizations l10n) {
    final amount = _parseDigits(_amountController.text).toDouble();
    final fee = 0.0;
    final net = amount - fee;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _detailRow(l10n.withdrawAmount,
                '${_formatInput(amount.toInt().toString())} VND', isDark),
            const Divider(),
            _detailRow(l10n.withdrawFee, '0 VND', isDark),
            const Divider(thickness: 2),
            _detailRow(
              l10n.netAmount,
              '${_formatInput(net.toInt().toString())} VND',
              isDark,
              bold: true,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? AppColors.onBackgroundDark
                  : AppColors.onBackgroundLight,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ??
                  (isDark
                      ? AppColors.onSurfaceDark
                      : AppColors.onSurfaceLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(
      WalletState state, Color primaryColor, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.withdrawStatus == WithdrawStatus.loading
            ? null
            : _submitWithdraw,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: state.withdrawStatus == WithdrawStatus.loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                l10n.confirmWithdraw,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildNote(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.processingNote,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatInput(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final num = int.tryParse(digits) ?? 0;
    return num.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
