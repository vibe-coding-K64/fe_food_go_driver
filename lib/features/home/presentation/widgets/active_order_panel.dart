import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/entities/order.dart';
import '../pages/order_map_screen.dart';

class ActiveOrderPanel extends StatelessWidget {
  final Order order;
  final bool isUpdatingStatus;
  final VoidCallback onPickedUp;
  final VoidCallback onDelivered;
  final VoidCallback onCancelled;

  const ActiveOrderPanel({
    super.key,
    required this.order,
    required this.isUpdatingStatus,
    required this.onPickedUp,
    required this.onDelivered,
    required this.onCancelled,
  });

  Color _statusColor(bool isDark) {
    switch (order.statusCode) {
      case 'DELIVERING':
        return AppColors.busy;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.errorLight;
      default:
        return isDark ? AppColors.primaryDark : AppColors.primaryLight;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (order.statusCode) {
      case 'PENDING_STORE_CONFIRMATION':
        return l10n.waitingForOrder;
      case 'WAITING_DRIVER':
        return l10n.pickup;
      case 'DELIVERING':
        return l10n.delivering;
      case 'COMPLETED':
        return l10n.delivered;
      case 'CANCELLED':
        return l10n.cancelled;
      default:
        return order.statusDescription ?? l10n.status;
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: '', decimalDigits: 0);
    return formatter.format(amount);
  }

  Future<void> _openNavigation(LatLng destination) async {
    final uri = Uri.parse(
      'https://www.openstreetmap.org/directions'
      '?engine=osrm_car'
      '&route=${destination.latitude},${destination.longitude}#map=16/${destination.latitude}/${destination.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMaps() async {
    final hasCoords = order.deliveryLat != null && order.deliveryLng != null;
    if (hasCoords) {
      _openNavigation(LatLng(order.deliveryLat!, order.deliveryLng!));
    } else {
      final encoded = Uri.encodeComponent(order.deliveryAddress);
      final uri = Uri.parse('https://www.openstreetmap.org/search?query=$encoded#map=16');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openMapScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderMapScreen(order: order)),
    );
  }

  Future<void> _callReceiver() async {
    final phone = order.displayRecipientPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final statusColor = _statusColor(isDark);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.activeOrder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(l10n),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.orderCode.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          '${l10n.orderCode}: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            order.orderCode,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow(Icons.store, order.storeName, isDark),
                  if (order.storeAddress != null)
                    _buildInfoRow(Icons.location_on, order.storeAddress!, isDark, iconColor: primaryColor),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.person, order.displayRecipientName, isDark),
                  if (order.displayRecipientPhone != null)
                    _buildInfoRow(Icons.phone, order.displayRecipientPhone!, isDark, isBold: true),
                  _buildInfoRow(Icons.home, order.deliveryAddress, isDark, maxLines: 2),
                  if (order.note != null && order.note!.isNotEmpty)
                    _buildInfoRow(Icons.note, order.note!, isDark, iconColor: AppColors.warning),
                  const SizedBox(height: 12),
                  if (order.estimatedDurationMinutes != null) ...[
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight),
                        const SizedBox(width: 8),
                        Text(
                          'Du kien: ${order.estimatedDurationMinutes!} phut',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Text(
                        '${l10n.homeDeliveryFee}: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(order.driverCollectAmount)} VND',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.navigation, size: 18),
                          label: Text(l10n.navigate),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openMapScreen(context),
                          icon: const Icon(Icons.map, size: 18),
                          label: Text(l10n.map),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            side: const BorderSide(color: AppColors.primaryLight),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _callReceiver,
                          icon: const Icon(Icons.phone, size: 18),
                          label: Text(l10n.call),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.success,
                            side: const BorderSide(color: AppColors.success),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.statusCode == 'DELIVERING') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUpdatingStatus ? null : onPickedUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isUpdatingStatus
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l10n.pickup),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUpdatingStatus ? null : onDelivered,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isUpdatingStatus
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(l10n.complete),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    bool isDark, {
    Color? iconColor,
    int maxLines = 1,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: iconColor ??
                (isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color:
                    isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
