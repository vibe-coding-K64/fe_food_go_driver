import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../injection_container.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../chat/presentation/bloc/chat_bloc.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import 'order_map_screen.dart';

class _TimelineStep {
  final IconData icon;
  final String label;
  final DateTime? time;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.icon,
    required this.label,
    required this.time,
    required this.isCompleted,
    required this.isActive,
  });
}

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _showAllItems = false;
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

  String _paymentMethodLabel(int paymentMethod, AppLocalizations l10n) {
    switch (paymentMethod) {
      case 1:
        return l10n.paymentMethodCash;
      case 2:
        return l10n.paymentMethodEWallet;
      case 3:
        return l10n.paymentMethodBankCard;
      default:
        return l10n.paymentMethodUnknown;
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.callPhone),
        content: Text(l10n.phoneNumber(phone)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _launchPhoneCall(phone);
            },
            child: Text(l10n.callPhone),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _copyToClipboard(String text) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.copy),
        content: Text(l10n.copiedToClipboard(text)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => BlocProvider<ChatBloc>.value(
          value: getIt<ChatBloc>(),
          child: ChatScreen(
            orderId: widget.order.id,
            order: widget.order,
          ),
        ),
      ),
    );
  }

  String _hideName(String name) {
    if (name.length <= 2) return name;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshOrder() async {
    final bloc = context.read<HomeBloc>();
    bloc.add(const RefreshAllDataRequested());
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetail),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
              if (widget.order.storeLat != null || widget.order.deliveryLat != null) ...[
                const SizedBox(height: 16),
                _buildMapNavigationCard(isDark, primaryColor, l10n),
              ],
              if (widget.order.deliveryPhotoUrl != null &&
                  widget.order.deliveryPhotoUrl!.isNotEmpty)
                _buildSectionDeliveryPhoto(isDark, primaryColor, l10n),
              const SizedBox(height: 16),
              _buildDeliveryTimeline(isDark, primaryColor, l10n),
              if (widget.order.isCompleted) ...[
                const SizedBox(height: 16),
                _buildSectionDeliverySuccess(isDark, primaryColor),
              ],
              const SizedBox(height: 24),
              _buildSection6ActionButtons(isDark, primaryColor, l10n),
              const SizedBox(height: 80),
            ],
          ),
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
                        l10n.deliveryAddress,
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
                if (widget.order.driverId != null && widget.order.driverId!.isNotEmpty)
                  IconButton(
                    onPressed: () => _openChat(context),
                    icon: const Icon(Icons.chat, size: 22),
                    style: IconButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                    ),
                    tooltip: l10n.chatWithCustomer,
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
              final showAll = _showAllItems || index < 2;
              return Column(
                children: [
                  if (!_showAllItems && index == 2)
                    TextButton(
                      onPressed: () => setState(() => _showAllItems = true),
                      child: Text(
                        l10n.moreItems(widget.order.items.length - 2),
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
                  _paymentMethodLabel(widget.order.paymentMethod, l10n),
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
                    widget.order.paymentStatus == 2 ? l10n.paidStatus : l10n.unpaidStatus,
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

  Widget _buildDeliveryTimeline(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        icon: Icons.receipt_outlined,
        label: l10n.waitingForOrder,
        time: null,
        isCompleted: true,
        isActive: false,
      ),
      _TimelineStep(
        icon: Icons.store_outlined,
        label: l10n.confirmPickup,
        time: widget.order.arrivedAtStoreAt,
        isCompleted: widget.order.pickedUpAt != null || widget.order.statusCode == 'DELIVERING' || widget.order.isCompleted,
        isActive: widget.order.arrivedAtStoreAt != null && !widget.order.isCompleted,
      ),
      _TimelineStep(
        icon: Icons.local_shipping_outlined,
        label: l10n.deliveringNow,
        time: widget.order.pickedUpAt,
        isCompleted: widget.order.isCompleted,
        isActive: widget.order.pickedUpAt != null && !widget.order.isCompleted,
      ),
      _TimelineStep(
        icon: Icons.check_circle_outline,
        label: l10n.completed,
        time: widget.order.deliveredAt,
        isCompleted: widget.order.isCompleted,
        isActive: false,
      ),
    ];

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
                Icon(Icons.timeline, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.orderTimeline,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map<Widget>((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: step.isCompleted
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : step.isActive
                                      ? primaryColor.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step.icon,
                              size: 18,
                              color: step.isCompleted
                                  ? AppColors.success
                                  : step.isActive
                                      ? primaryColor
                                      : Colors.grey,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: step.isCompleted
                                    ? AppColors.success.withValues(alpha: 0.4)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: step.isActive ? FontWeight.bold : FontWeight.w500,
                                color: step.isCompleted
                                    ? AppColors.success
                                    : step.isActive
                                        ? (isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight)
                                        : Colors.grey,
                              ),
                            ),
                            if (step.time != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                _formatDateTime(step.time!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionDeliverySuccess(bool isDark, Color primaryColor) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: AppColors.success.withValues(alpha: 0.08),
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
                    color: AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deliverySuccess,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      if (widget.order.deliveredAt != null)
                        Text(
                          _formatDateTime(widget.order.deliveredAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.order.deliveryPhotoUrl != null && widget.order.deliveryPhotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(widget.order.deliveryPhotoUrl!),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade200,
                    ),
                    child: Image.network(
                      widget.order.deliveryPhotoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        final l10n = AppLocalizations.of(context)!;
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                l10n.unableToLoadImage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              TextButton(
                                onPressed: () => setState(() {}),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.tapToViewFullImage,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapNavigationCard(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    final hasStore = widget.order.storeLat != null && widget.order.storeLng != null;
    final hasDelivery = widget.order.deliveryLat != null && widget.order.deliveryLng != null;

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
                Icon(Icons.map, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.map,
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
              children: [
                if (hasStore) ...[
                  Expanded(
                    child: _buildLocationChip(
                      Icons.store,
                      widget.order.storeName,
                      AppColors.warning,
                      () => _openMap(widget.order.storeLat, widget.order.storeLng),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (hasDelivery)
                  Expanded(
                    child: _buildLocationChip(
                      Icons.home,
                      widget.order.deliveryAddress,
                      AppColors.info,
                      () => _openMap(widget.order.deliveryLat, widget.order.deliveryLng),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openFullMapScreen(context, widget.order),
                icon: const Icon(Icons.map_outlined, size: 20),
                label: Text(l10n.openMaps),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationChip(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullMapScreen(BuildContext context, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => OrderMapScreen(order: order),
      ),
    );
  }

  Widget _buildSectionDeliveryPhoto(
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.camera_alt, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      l10n.deliveryConfirmationPhoto,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(widget.order.deliveryPhotoUrl!),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                      ),
                      child: Image.network(
                        widget.order.deliveryPhotoUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.unableToLoadImage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(() {}),
                                  child: Text(l10n.retry),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tapToViewFullImage,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      final l10n = AppLocalizations.of(context)!;
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, size: 64, color: Colors.white70),
                            const SizedBox(height: 8),
                            Text(
                              l10n.unableToLoadImage,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
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
          child: ElevatedButton.icon(
            onPressed: () => _handleTakePhoto(l10n),
            icon: const Icon(Icons.camera_alt, size: 20),
            label: Text(
              l10n.confirmDelivered,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _handleTakePhoto(AppLocalizations l10n) async {
    final bloc = context.read<HomeBloc>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.complete,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.takeDeliveryPhotoToComplete,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryLight),
                title: Text(l10n.takePhoto),
                subtitle: Text(l10n.takePhotoDescription),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadPhoto(bloc, ImageSource.camera, l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryLight),
                title: Text(l10n.selectFromGallery),
                subtitle: Text(l10n.selectFromGalleryDescription),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUploadPhoto(bloc, ImageSource.gallery, l10n);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
    HomeBloc bloc,
    ImageSource source,
    AppLocalizations l10n,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) return;

      bloc.add(CompleteOrderWithPhotoPressed(
        orderId: widget.order.id,
        photoPath: photo.path,
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.imagePickerError(e.toString()))),
        );
      }
    }
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
    String? selectedReason;
    final noteController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.reportIssue,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...issues.map((issue) => RadioListTile<String>(
                    title: Text(issue, style: const TextStyle(fontSize: 14)),
                    value: issue,
                    groupValue: selectedReason,
                    onChanged: (v) => setSheetState(() => selectedReason = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '${l10n.note}...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedReason == null || isSubmitting
                      ? null
                      : () async {
                          setSheetState(() => isSubmitting = true);
                          final bloc = context.read<HomeBloc>();
                          final success = await bloc.reportOrderIssue(
                            widget.order.id,
                            selectedReason!,
                            noteController.text,
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            if (success) {
                              _showSnackBar(l10n.reportSubmitSuccess, isError: false);
                            } else {
                              _showSnackBar(l10n.reportSubmitFailed, isError: true);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.reportIssue, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => noteController.dispose());
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.errorLight : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
