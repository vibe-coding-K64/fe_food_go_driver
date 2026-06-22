import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../orders/domain/entities/order.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/available_order_card.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Future<void> _acceptOrder(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmReceiveOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.doYouWantToAcceptOrder),
            const SizedBox(height: 8),
            Text(
              order.storeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(l10n.deliveryFeeAmount('${_formatCurrency(order.deliveryFee)}')),
          ],
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
            child: Text(l10n.acceptOrder),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    context.read<HomeBloc>().add(AcceptAvailableOrder(order.id));
  }

  Future<void> _declineOrder(Order order) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeclineOrder),
        content: Text(l10n.areYouSureDeclineOrder),
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

    context.read<HomeBloc>().add(DeclineAvailableOrder(order.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage ||
          prev.isAcceptingOrder != curr.isAcceptingOrder,
      listener: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        if (state.isAcceptingOrder) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              content: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(l10n.processing),
                ],
              ),
            ),
          );
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.errorLight),
                    const SizedBox(width: 8),
                    Text(l10n.notifications),
                  ],
                ),
                content: Text(state.errorMessage!),
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
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.availableOrders),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<HomeBloc>().add(const RefreshAvailableOrdersRequested());
              },
            ),
          ],
        ),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            final orders = state.availableOrders;

            if (state.status == HomeStatus.loading && orders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (orders.isEmpty) {
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
              onRefresh: () async {
                context.read<HomeBloc>().add(const RefreshAvailableOrdersRequested());
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AvailableOrderCard(
                      order: order,
                      formatCurrency: _formatCurrency,
                      onAccept: () => _acceptOrder(order),
                      onDecline: () => _declineOrder(order),
                      l10n: l10n,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
