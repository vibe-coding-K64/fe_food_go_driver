import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/data/models/order_model.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../widgets/available_order_card.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  Timer? _pollingTimer;
  List<OrderModel> _availableOrders = [];
  bool _isLoading = true;
  String? _error;
  final http.Client _client = http.Client();

  @override
  void initState() {
    super.initState();
    _loadAvailableOrders();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _client.close();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      _loadAvailableOrders(showLoading: false);
    });
  }

  Future<void> _loadAvailableOrders({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }
    try {
      final orders = await _fetchAvailableOrders();
      if (mounted) {
        setState(() {
          _availableOrders = orders;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<List<OrderModel>> _fetchAvailableOrders() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConstants.baseApiUrl}/drivers/orders/available'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final List<dynamic> data;
        if (decoded is Map<String, dynamic>) {
          final rawData = decoded['data'];
          if (rawData is List) {
            data = rawData;
          } else {
            return [];
          }
        } else if (decoded is List) {
          data = decoded;
        } else {
          return [];
        }
        return data
            .map((json) =>
                OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _acceptOrder(OrderModel order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homeAccept),
        content: Text(
          '${l10n.pickupOrderConfirm(order.storeName)}\n\n${l10n.homeDeliveryFee}: ${_formatCurrency(order.deliveryFee)} VND',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.homeAccept),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final resp = await _client
          .post(
            Uri.parse(
                '${AppConstants.baseApiUrl}/drivers/orders/${order.id}/accept'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.orderTaken),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
          context.read<HomeBloc>().add(const HomeLoadRequested());
        }
      } else if (resp.statusCode == 409) {
        if (mounted) {
          setState(() => _availableOrders.removeWhere((o) => o.id == order.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.orderTaken),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resp.reasonPhrase ?? 'Error'),
              backgroundColor: AppColors.errorLight,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _declineOrder(OrderModel order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.decline),
        content: Text(l10n.cancelOrderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.decline),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _client
          .post(
            Uri.parse(
                '${AppConstants.baseApiUrl}/drivers/orders/${order.id}/decline'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() => _availableOrders.removeWhere((o) => o.id == order.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.orderDeclined),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _availableOrders.removeWhere((o) => o.id == order.id));
      }
    }
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.availableOrders),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAvailableOrders(),
          ),
        ],
      ),
      body: _buildBody(isDark, l10n),
    );
  }

  Widget _buildBody(bool isDark, AppLocalizations l10n) {
    if (_isLoading && _availableOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _availableOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.errorLight),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadAvailableOrders(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_availableOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delivery_dining,
              size: 64,
              color: isDark ? AppColors.outlineDark : AppColors.outlineLight,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noAvailableOrders,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.onBackgroundDark
                    : AppColors.onBackgroundLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAvailableOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _availableOrders.length,
        itemBuilder: (context, index) {
          final order = _availableOrders[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AvailableOrderCard(
              order: order,
              formatCurrency: _formatCurrency,
              onAccept: () => _acceptOrder(order),
              onDecline: () => _declineOrder(order),
            ),
          );
        },
      ),
    );
  }
}
