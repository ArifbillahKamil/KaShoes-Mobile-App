import 'package:flutter/material.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/location/presentation/screens/location_sharing_screen.dart';
import '../../features/order/presentation/screens/order_detail_screen.dart';
import '../../features/order/presentation/screens/order_form_screen.dart';
import '../../features/order/presentation/screens/order_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Named route configuration.
/// Using Navigator 1.0 (pushNamed) for simplicity.
/// 
/// Routes:
///   /          → SplashScreen
///   /login     → LoginScreen
///   /register  → RegisterScreen
///   /dashboard → DashboardScreen
///   /orders    → OrderListScreen
///   /orders/new → OrderFormScreen
///   /orders/:id → OrderDetailScreen
///   /location/:orderId → LocationSharingScreen
///   /profile   → ProfileScreen
Route<dynamic> generateRoute(RouteSettings settings) {
  final name = settings.name ?? '/';
  // final args = settings.arguments;

  // Parse order ID from route name like '/orders/123'
  if (name.startsWith('/orders/') && name != '/orders/new') {
    final idStr = name.substring('/orders/'.length);
    final id = int.tryParse(idStr);
    if (id != null) {
      return _pageRoute(OrderDetailScreen(orderId: id), settings);
    }
  }

  // Parse order ID from location route '/location/123'
  if (name.startsWith('/location/')) {
    final idStr = name.substring('/location/'.length);
    final id = int.tryParse(idStr);
    if (id != null) {
      return _pageRoute(LocationSharingScreen(orderId: id), settings);
    }
  }

  switch (name) {
    case '/':
      return _pageRoute(const SplashScreen(), settings);
    case '/login':
      return _pageRoute(const LoginScreen(), settings);
    case '/register':
      return _pageRoute(const RegisterScreen(), settings);
    case '/dashboard':
      return _pageRoute(const DashboardScreen(), settings);
    case '/orders':
      return _pageRoute(const OrderListScreen(), settings);
    case '/orders/new':
      return _pageRoute(const OrderFormScreen(), settings);
    case '/profile':
      return _pageRoute(const ProfileScreen(), settings);
    default:
      return _pageRoute(const _NotFoundScreen(), settings);
  }
}

PageRouteBuilder<dynamic> _pageRoute(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text('Halaman tidak ditemukan'),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    );
  }
}
