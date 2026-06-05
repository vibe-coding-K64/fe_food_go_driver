import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../l10n/app_localizations.dart';
import '../../../injection_container.dart';
import '../../auth/presentation/pages/login_page_wrapper.dart';
import '../../home/presentation/pages/home_page.dart';
import '../../home/presentation/pages/orders_screen.dart';
import '../../home/presentation/pages/wallet_screen.dart';
import '../../home/presentation/pages/profile_screen.dart';
import '../../home/presentation/widgets/driver_bottom_nav.dart';
import '../../home/presentation/widgets/home_app_bar.dart';
import '../../home/presentation/bloc/home_bloc.dart';
import '../../home/presentation/bloc/home_event.dart';
import '../../home/presentation/bloc/home_state.dart';
import '../../auth/presentation/bloc/login_bloc.dart';
import '../../auth/presentation/bloc/login_state.dart';
import 'bloc/theme/theme_bloc.dart';
import 'bloc/theme/theme_event.dart';
import 'bloc/theme/theme_state.dart';
import 'bloc/locale/locale_bloc.dart';
import 'bloc/locale/locale_event.dart';
import 'bloc/locale/locale_state.dart';
import '../../../core/theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (_) => getIt<ThemeBloc>()..add(const LoadTheme()),
        ),
        BlocProvider<LocaleBloc>(
          create: (_) => getIt<LocaleBloc>()..add(const LoadLocale()),
        ),
        BlocProvider<HomeBloc>(
          create: (_) => getIt<HomeBloc>(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp(
                navigatorKey: appNavigatorKey,
                title: 'Food Go Driver',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeState.themeMode,
                locale: localeState.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                initialRoute: '/',
                onGenerateRoute: (settings) {
                  if (settings.name == '/') {
                    return MaterialPageRoute(
                      builder: (_) => BlocProvider<LoginBloc>(
                        create: (_) => getIt<LoginBloc>(),
                        child: const _AuthGate(),
                      ),
                    );
                  }
                  return null;
                },
                home: BlocProvider<LoginBloc>(
                  create: (_) => getIt<LoginBloc>(),
                  child: const _AuthGate(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (ctx, state) {
        if (state is SessionValidating || state is LoginInitial) {
          return const _SessionValidatingScreen();
        }

        if (state is SessionValid || state is LoginSuccess) {
          return const _MainShell();
        }

        return const LoginPageWrapper();
      },
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell();

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeBloc>().add(const HomeLoadRequested());
      }
    });
  }

  @override
  void dispose() {
    context.read<HomeBloc>().add(const HomeStopListening());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          appBar: HomeAppBar(state: state),
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              HomePage(),
              OrdersScreen(),
              WalletScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: DriverBottomNav(
            currentIndex: _currentIndex,
            onTap: (index) {
              if (index == _currentIndex) return;
              setState(() => _currentIndex = index);
            },
          ),
        );
      },
    );
  }
}

class _SessionValidatingScreen extends StatelessWidget {
  const _SessionValidatingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.delivery_dining,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Dang xac minh phien dang nhap...',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
