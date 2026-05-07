import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/bakery_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/grok_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/reservation_provider.dart';
import 'routes/app_routes.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/app_shell.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ThePastryPathApp());
}

class ThePastryPathApp extends StatelessWidget {
  const ThePastryPathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => BakeryProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => GrokProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
      ],
      child: MaterialApp(
        title: 'The Pastry Path',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.auth: (_) => const AuthScreen(),
          AppRoutes.shell: (_) => const AppShell(),
        },
      ),
    );
  }
}
