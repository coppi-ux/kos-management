import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/kos_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/addon_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/tenant_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/role_select_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<KosProvider>(
          create: (_) => KosProvider(),
        ),
        ChangeNotifierProvider<BillProvider>(
          create: (_) => BillProvider(),
        ),
        ChangeNotifierProvider<AddonProvider>(
          create: (_) => AddonProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider<AnalyticsProvider>(
          create: (_) => AnalyticsProvider(),
        ),
        ChangeNotifierProvider<TenantProvider>(
          create: (_) => TenantProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Kos Management',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(
          nextScreen: RoleSelectScreen(),
        ),
      ),
    );
  }
}