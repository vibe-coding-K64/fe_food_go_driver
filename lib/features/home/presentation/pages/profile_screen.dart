import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/bloc/login_bloc.dart';
import '../../../auth/presentation/bloc/login_event.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../core/presentation/bloc/theme/theme_bloc.dart';
import '../../../core/presentation/bloc/theme/theme_event.dart';
import '../../../core/presentation/bloc/theme/theme_state.dart';
import '../../../core/presentation/bloc/locale/locale_bloc.dart';
import '../../../core/presentation/bloc/locale/locale_state.dart';
import '../../../core/presentation/bloc/locale/locale_event.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final profile = state.driverProfile;
        final stats = state.todayStats;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.profile),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAvatarSection(context, profile, isDark, primaryColor, l10n),
                const SizedBox(height: 24),
                _buildStatsSection(stats, isDark, primaryColor, l10n),
                const SizedBox(height: 24),
                _buildSettingsSection(context, isDark, primaryColor, l10n),
                const SizedBox(height: 24),
                _buildLogoutButton(context, isDark, l10n),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSection(
    BuildContext context,
    dynamic profile,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: primaryColor,
          backgroundImage:
              profile?.photoUrl != null ? NetworkImage(profile!.photoUrl!) : null,
          child: profile?.photoUrl == null
              ? Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          profile?.fullName ?? l10n.welcomeDriver,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              '${profile?.rating.toStringAsFixed(1) ?? '0.0'} / 5.0',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          profile?.phoneNumber ?? '',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    dynamic stats,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.driverInfo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile(
                  Icons.route,
                  stats?.totalOrders.toString() ?? '0',
                  l10n.totalTrips,
                  isDark,
                  null,
                ),
                _buildStatTile(
                  Icons.star,
                  stats?.rating.toStringAsFixed(1) ?? '0.0',
                  l10n.rating,
                  isDark,
                  Colors.amber,
                ),
                _buildStatTile(
                  Icons.monetization_on,
                  _formatCurrency(stats?.earningsToday ?? 0),
                  l10n.earningsToday,
                  isDark,
                  AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    IconData icon,
    String value,
    String label,
    bool isDark,
    Color? iconColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor ?? (isDark ? AppColors.primaryDark : AppColors.primaryLight),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    AppLocalizations l10n,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              return _buildSettingsTile(
                Icons.language,
                l10n.language,
                localeState.locale?.languageCode == 'vi' ? 'Tiếng Việt' : 'English',
                () => _showLanguageSheet(context, l10n),
                isDark,
                primaryColor,
                null,
              );
            },
          ),
          const Divider(height: 1),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return _buildSettingsTile(
                Icons.dark_mode,
                l10n.darkMode,
                themeState.themeMode == ThemeMode.dark
                    ? l10n.darkMode
                    : l10n.lightMode,
                null,
                isDark,
                primaryColor,
                Switch(
                  value: themeState.themeMode == ThemeMode.dark,
                  onChanged: (_) {
                    context.read<ThemeBloc>().add(const ToggleTheme());
                  },
                  activeColor: primaryColor,
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            Icons.info_outline,
            l10n.settings,
            'v1.0.0',
            null,
            isDark,
            primaryColor,
            const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
    bool isDark,
    Color primaryColor,
    Widget? trailing,
  ) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.onBackgroundDark : AppColors.onBackgroundLight,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(
      BuildContext context, bool isDark, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context, l10n),
        icon: const Icon(Icons.logout),
        label: Text(l10n.logout),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.errorLight,
          side: const BorderSide(color: AppColors.errorLight),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              l10n.changeLanguage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<LocaleBloc, LocaleState>(
              builder: (context, state) {
                return Column(
                  children: [
                    ListTile(
                      title: const Text('Tiếng Việt'),
                      trailing: state.locale?.languageCode == 'vi'
                          ? const Icon(Icons.check, color: AppColors.primaryLight)
                          : null,
                      onTap: () {
                        context
                            .read<LocaleBloc>()
                            .add(const ChangeLocale(Locale('vi')));
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      title: const Text('English'),
                      trailing: state.locale?.languageCode == 'en'
                          ? const Icon(Icons.check, color: AppColors.primaryLight)
                          : null,
                      onTap: () {
                        context
                            .read<LocaleBloc>()
                            .add(const ChangeLocale(Locale('en')));
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text('${l10n.logout}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final newLoginBloc = getIt<LoginBloc>();
              newLoginBloc.add(const LogoutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<LoginBloc>.value(
                    value: newLoginBloc,
                    child: const LoginPage(),
                  ),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorLight,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
