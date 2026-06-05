import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final HomeState state;

  const HomeAppBar({super.key, required this.state});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showLocationPermissionDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.locationService),
        content: Text(
          state.errorMessage ?? l10n.locationServiceDisabled,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(const ClearLocationPermissionRequest());
            },
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(const ClearLocationPermissionRequest());
              context.read<HomeBloc>().add(const ToggleDriverStatus());
            },
            child: Text(l10n.locationPermissionDenied),
          ),
        ],
      ),
    );
  }

  void _onToggleTap(BuildContext context) {
    if (state.isTogglingStatus) return;

    final bloc = context.read<HomeBloc>();

    if (!state.isOnline) {
      bloc.add(const ToggleDriverStatus());
    } else {
      bloc.add(const ToggleDriverStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final profile = state.driverProfile;

    return BlocListener<HomeBloc, HomeState>(
      listenWhen: (previous, current) =>
          current.needsLocationPermission && !previous.needsLocationPermission,
      listener: (context, current) {
        _showLocationPermissionDialog(context);
      },
      child: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            backgroundImage: profile?.photoUrl != null
                ? NetworkImage(profile!.photoUrl!)
                : null,
            child: profile?.photoUrl == null
                ? Icon(
                    Icons.person,
                    color: isDark ? Colors.black : Colors.white,
                  )
                : null,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              profile?.fullName ?? l10n.welcomeDriver,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (profile != null) ...[
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    profile.rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          _buildOnlineToggle(context, isDark, l10n),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.errorLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle(BuildContext context, bool isDark, AppLocalizations l10n) {
    final isOnline = state.isOnline;
    final isLoading = state.isTogglingStatus;
    final onlineColor = AppColors.online;
    final offlineColor = AppColors.offline;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GestureDetector(
        onTap: state.isTogglingStatus ? null : () => _onToggleTap(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOnline
                ? onlineColor.withValues(alpha: 0.2)
                : offlineColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOnline ? onlineColor : offlineColor,
              width: 2,
            ),
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: onlineColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 8,
                  height: 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isOnline ? onlineColor : offlineColor,
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline ? onlineColor : offlineColor,
                    shape: BoxShape.circle,
                    boxShadow: isOnline
                        ? [
                            BoxShadow(
                              color: onlineColor,
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                isLoading
                    ? '...'
                    : (isOnline ? l10n.online : l10n.offline),
                style: TextStyle(
                  color: isOnline ? onlineColor : offlineColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
