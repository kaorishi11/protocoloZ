import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/factions/faction_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/expeditions/expeditions_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/map/shelter_map_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final onAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';
    if (session == null && !onAuth && state.matchedLocation != '/') return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/faction', builder: (_, __) => const FactionScreen()),
    ShellRoute(
      builder: (_, state, child) => GameShell(location: state.matchedLocation, child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
        GoRoute(path: '/expeditions', builder: (_, __) => const ExpeditionsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/map', builder: (_, __) => const ShelterMapScreen()),
      ],
    ),
  ],
);

class ProtocoloZApp extends StatelessWidget {
  const ProtocoloZApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Protocolo Z',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        routerConfig: _router,
      );
}

class GameShell extends StatelessWidget {
  final String location;
  final Widget child;
  const GameShell({super.key, required this.location, required this.child});

  int get _index {
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/expeditions')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const paths = ['/home', '/inventory', '/expeditions', '/profile'];
    const icons = [Icons.shield_outlined, Icons.inventory_2_outlined, Icons.explore_outlined, Icons.person_outline];
    const labels = ['Base', 'Mochila', 'Expedições', 'Perfil'];
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => context.go(paths[i]),
        destinations: List.generate(4, (i) => NavigationDestination(icon: Icon(icons[i]), label: labels[i])),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }
  late final dynamic _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
