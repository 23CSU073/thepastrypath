import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await context.read<AppAuthProvider>().loadRememberLogin();
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    final auth = context.read<AppAuthProvider>();
    Navigator.pushReplacementNamed(context, auth.user == null ? AppRoutes.auth : AppRoutes.shell);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cream, AppColors.orange, AppColors.warmBrown],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 18))],
                  ),
                  child: const Icon(Icons.bakery_dining_rounded, color: AppColors.warmBrown, size: 54),
                ),
                const SizedBox(height: 22),
                const Text('The Pastry Path', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                const Text('fresh finds around you', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
