import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/data/models/order_request_model.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';

class OrderRequestModal extends StatefulWidget {
  final OrderRequestModel request;
  final HomeBloc homeBloc;

  const OrderRequestModal({
    super.key,
    required this.request,
    required this.homeBloc,
  });

  @override
  State<OrderRequestModal> createState() => _OrderRequestModalState();
}

class _OrderRequestModalState extends State<OrderRequestModal>
    with SingleTickerProviderStateMixin {
  static const int _totalSeconds = 10;
  int _remainingSeconds = _totalSeconds;
  Timer? _timer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: _totalSeconds),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );
    _progressController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _onAccept() {
    _timer?.cancel();
    _progressController.stop();
    widget.homeBloc.add(RespondToOrderRequest(
          requestId: widget.request.id,
          orderId: widget.request.orderId,
          action: 'accept',
        ));
    Navigator.of(context).pop();
  }

  void _onDecline() {
    _timer?.cancel();
    _progressController.stop();
    widget.homeBloc.add(RespondToOrderRequest(
          requestId: widget.request.id,
          orderId: widget.request.orderId,
          action: 'decline',
        ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final order = widget.request.orderData;

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_active,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.newOrderRequest,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _remainingSeconds <= 3
                            ? AppColors.errorLight
                            : Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tu dong tu choi sau ${_remainingSeconds}s',
                    style: TextStyle(
                      fontSize: 13,
                      color: _remainingSeconds <= 3
                          ? AppColors.errorLight
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (order != null) ...[
                  _buildInfoRow(
                    Icons.store,
                    'Cua hang',
                    order.storeName,
                    isDark,
                  ),
                  _buildInfoRow(
                    Icons.location_on,
                    'Dia chi giao',
                    order.deliveryAddress,
                    isDark,
                  ),
                  _buildInfoRow(
                    Icons.delivery_dining,
                    'Thu nhap uoc tinh',
                    '${(order.estimatedEarning ?? 0).toStringAsFixed(0)} VND',
                    isDark,
                  ),
                  _buildInfoRow(
                    Icons.payments,
                    'Thanh toan',
                    order.paymentMethod,
                    isDark,
                  ),
                  if (order.receiverName != null)
                    _buildInfoRow(
                      Icons.person,
                      'Nguoi nhan',
                      '${order.receiverName}${order.receiverPhone != null ? ' - ${order.receiverPhone}' : ''}',
                      isDark,
                    ),
                  if (order.note != null && order.note!.isNotEmpty)
                    _buildInfoRow(
                      Icons.note,
                      'Ghi chu',
                      order.note!,
                      isDark,
                    ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Don hang #${widget.request.orderId.substring(0, widget.request.orderId.length.clamp(0, 8))}...',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onDecline,
                    icon: const Icon(Icons.close),
                    label: Text(l10n.decline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorLight,
                      side: const BorderSide(color: AppColors.errorLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _onAccept,
                    icon: const Icon(Icons.check),
                    label: Text(l10n.accept),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
