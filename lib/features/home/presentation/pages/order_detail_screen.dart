import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (widget.order.statusCode) {
      case 'PENDING_STORE_CONFIRMATION':
        return l10n.waitingForOrder;
      case 'WAITING_DRIVER':
        return l10n.pickup;
      case 'DELIVERING':
        return l10n.deliveringNow;
      case 'COMPLETED':
        return l10n.completed;
      case 'CANCELLED':
        return l10n.cancelled;
      default:
        return widget.order.statusDescription ?? '';
    }
  }

  Color _statusColor() {
    switch (widget.order.statusCode) {
      case 'PENDING_STORE_CONFIRMATION':
        return AppColors.warning;
      case 'WAITING_DRIVER':
        return AppColors.info;
      case 'DELIVERING':
        return AppColors.primaryLight;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.errorLight;
      default:
        return AppColors.outlineLight;
    }
  }

  String _paymentMethodLabel(int paymentMethod) {
    switch (paymentMethod) {
      case 1:
        return 'MoMo';
      case 2:
        return 'Tiền mặt (COD)';
      case 3:
        return 'ZaloPay';
      case 4:
        return 'Thẻ ngân hàng';
      default:
        return 'Không xác định';
    }
  }

  void _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {}

    const defaultLat = 10.7769;
    const defaultLng = 106.7009;
    final oriLat = position != null ? position.latitude.toStringAsFixed(6) : defaultLat.toString();
    final oriLng = position != null ? position.longitude.toStringAsFixed(6) : defaultLng.toString();

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${oriLat},${oriLng}'
      '&destination=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}'
      '&travelmode=driving',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _makeCall(String? phone) {
    if (phone == null || phone.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call: $phone'), duration: const Duration(seconds: 1)),
    );
  }

  void _copyToClipboard(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $text'), duration: const Duration(seconds: 1)),
    );
  }

  String _hideName(String name) {
    if (name.length <= 2) return name;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final statusColor = _statusColor();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetail),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection1StoreInfo(isDark, primaryColor, l10n),
            const SizedBox(height: 16),
            _buildSection2RecipientInfo(isDark, primaryColor, l10n),
            const SizedBox(height: 16),
            _buildSection3OrderItems(isDark, primaryColor, l10n),
            const SizedBox(height: 16),
            _buildSection4PaymentInfo(isDark, primaryColor, l10n),
            const SizedBox(height: 16),
            _buildSection5OrderInfo(isDark, primaryColor, l10n),
            const SizedBox(height: 24),
            _buildSection6ActionButtons(isDark, primaryColor, l10n),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSection1StoreInfo(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.storeName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                        ),
                      ),
                      if (widget.order.storeAddress != null)
                        GestureDetector(
                          onTap: () => _copyToClipboard(widget.order.storeAddress!),
                          child: Text(
                            widget.order.storeAddress!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _openMap(widget.order.storeLat, widget.order.storeLng),
                  icon: const Icon(Icons.navigation, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                  ),
                  tooltip: l10n.openMaps,
                ),
                IconButton(
                  onPressed: () => _makeCall(widget.order.displayRecipientPhone),
                  icon: const Icon(Icons.phone, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                  ),
                  tooltip: l10n.callReceiver,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection2RecipientInfo(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    final displayName = widget.order.displayRecipientName;
    final hiddenName = _hideName(displayName);

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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person, color: AppColors.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hiddenName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                        ),
                      ),
                      if (widget.order.displayRecipientPhone != null)
                        GestureDetector(
                          onTap: () => _copyToClipboard(widget.order.displayRecipientPhone!),
                          child: Text(
                            widget.order.displayRecipientPhone!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.info,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home, color: AppColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dia chi giao hang',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyToClipboard(widget.order.deliveryAddress),
                        child: Text(
                          widget.order.deliveryAddress,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => _openMap(widget.order.deliveryLat, widget.order.deliveryLng),
                  icon: const Icon(Icons.navigation, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                  ),
                  tooltip: l10n.openMaps,
                ),
                IconButton(
                  onPressed: () => _makeCall(widget.order.displayRecipientPhone),
                  icon: const Icon(Icons.phone, size: 22),
                  style: IconButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                  ),
                  tooltip: l10n.callReceiver,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection3OrderItems(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
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
                Icon(Icons.receipt, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.orderItems,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.order.items.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final item = entry.value;
              final showAll = index < 2;
              return Column(
                children: [
                  if (!showAll && index == 2)
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        '+ ${widget.order.items.length - 2} more items',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),
                  if (showAll || index >= 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: AppColors.surfaceLight,
                            ),
                            child: item.imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                                  )
                                : const Icon(Icons.fastfood, color: AppColors.outlineLight),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} x ${_formatCurrency(item.price)} VND',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                                  ),
                                ),
                                if (item.options != null && item.options!.isNotEmpty)
                                  ...item.options!.map((opt) => Text(
                                        '+ ${opt.name}: ${_formatCurrency(opt.price)} VND',
                                        style: const TextStyle(fontSize: 11, color: AppColors.outlineLight),
                                      )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (index < widget.order.items.length - 1) const Divider(),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSection4PaymentInfo(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
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
                const Icon(Icons.payment, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  l10n.paymentMethod,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _paymentMethodLabel(widget.order.paymentMethod),
                  style: TextStyle(
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.order.paymentStatus == 2 ? 'Da thanh toan' : 'Chua thanh toan',
                    style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.order.itemsSubtotal > 0 || widget.order.optionsSubtotal > 0) ...[
              _paymentRow(l10n.foodItems, widget.order.itemsSubtotal, isDark),
              if (widget.order.optionsSubtotal > 0)
                _paymentRow(l10n.toppingItems, widget.order.optionsSubtotal, isDark),
              if (widget.order.discountAmount > 0)
                _paymentRow(l10n.discount, -widget.order.discountAmount, isDark, isDiscount: true),
              _paymentRow(l10n.deliveryCharge, widget.order.deliveryFee, isDark),
              const Divider(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeDeliveryFee,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  ),
                ),
                Text(
                  '${_formatCurrency(widget.order.driverCollectAmount)} VND',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            if (widget.order.note != null && widget.order.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.order.note!, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentRow(String label, double amount, bool isDark, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${_formatCurrency(amount.abs())} VND',
            style: TextStyle(
              fontSize: 13,
              color: isDiscount
                  ? AppColors.success
                  : (isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection5OrderInfo(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.order.orderCode.isNotEmpty
                      ? widget.order.orderCode
                      : widget.order.id.substring(0, 6.clamp(0, widget.order.id.length)).toUpperCase(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(widget.order.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
              ),
            ),
            if (widget.order.distance != null) ...[
              const SizedBox(height: 4),
              Text(
                '${widget.order.distance!.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection6ActionButtons(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    final bloc = context.read<HomeBloc>();

    switch (widget.order.statusCode) {
      case 'PENDING_STORE_CONFIRMATION':
        return _buildStatus0Buttons(l10n);
      case 'WAITING_DRIVER':
        return _buildStatus1Buttons(bloc, l10n);
      case 'DELIVERING':
        return _buildStatus2Buttons(bloc, isDark, primaryColor, l10n);
      case 'COMPLETED':
      case 'CANCELLED':
        return _buildDisabledButton(_statusLabel(l10n));
      default:
        return _buildDisabledButton(widget.order.statusDescription ?? l10n.status);
    }
  }

  Widget _buildStatus0Buttons(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(l10n.waitingForOrder),
      ),
    );
  }

  Widget _buildStatus1Buttons(HomeBloc bloc, AppLocalizations l10n) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              bloc.add(ConfirmPickupPressed(widget.order.id));
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n.confirmPickup),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _showCancelConfirm(bloc, l10n),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorLight,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.cancelOrder),
          ),
        ),
      ],
    );
  }

  Widget _buildStatus2Buttons(
    HomeBloc bloc,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              bloc.add(CompleteOrderPressed(widget.order.id));
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n.confirmDelivered,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _showReportIssueSheet(l10n),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n.reportIssue),
          ),
        ),
      ],
    );
  }

  Widget _buildDisabledButton(String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }

  void _showCancelConfirm(HomeBloc bloc, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmCancelOrder),
        content: Text(l10n.confirmCancelOrderMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(CancelOrderPressed(widget.order.id));
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.cancelOrder),
          ),
        ],
      ),
    );
  }

  void _showReportIssueSheet(AppLocalizations l10n) {
    final issues = [
      l10n.reasonCantFindAddress,
      l10n.reasonCustomerNotAnswer,
      l10n.reasonStoreClosed,
      l10n.reasonTraffic,
      l10n.reasonOther,
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reportIssue,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...issues.map((issue) => ListTile(
                  title: Text(issue),
                  onTap: () {
                    Navigator.of(ctx).pop();
                  },
                )),
          ],
        ),
      ),
    );
  }
}
