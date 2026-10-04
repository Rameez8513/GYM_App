import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/member_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/plan_provider.dart';
import 'providers/settings_provider.dart';
import 'routing/app_router.dart';
import 'screens/auth/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.surface,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarDividerColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_failed) setState(() => _failed = false);
    final minimumSplash = Future.delayed(const Duration(milliseconds: 2000));
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      try {
        await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 6));
      } catch (_) {}
      await minimumSplash;
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const GymAdminApp();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _failed ? _StartupError(onRetry: _start) : const SplashScreen(),
    );
  }
}

class _StartupError extends StatelessWidget {
  final VoidCallback onRetry;

  const _StartupError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not start the app',
                  style: AppTextStyles.title, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text('Check your internet connection and try again.',
                  style: AppTextStyles.bodyMuted, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                  onPressed: onRetry, child: const Text('Try Again')),
            ],
          ),
        ),
      ),
    );
  }
}

class GymAdminApp extends StatelessWidget {
  const GymAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProxyProvider<AppAuthProvider, MemberProvider>(
          lazy: false,
          create: (_) => MemberProvider(),
          update: (_, auth, provider) => provider!..bind(auth.isLoggedIn),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, PlanProvider>(
          lazy: false,
          create: (_) => PlanProvider(),
          update: (_, auth, provider) => provider!..bind(auth.isLoggedIn),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, PaymentProvider>(
          lazy: false,
          create: (_) => PaymentProvider(),
          update: (_, auth, provider) => provider!..bind(auth.isLoggedIn),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, DashboardProvider>(
          lazy: false,
          create: (_) => DashboardProvider(),
          update: (_, auth, provider) => provider!..bind(auth.isLoggedIn),
        ),
        ChangeNotifierProxyProvider<AppAuthProvider, SettingsProvider>(
          lazy: false,
          create: (_) => SettingsProvider(),
          update: (_, auth, provider) => provider!..bind(auth.isLoggedIn),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.build(context);
          return MaterialApp.router(
            title: 'Joji Gym',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
