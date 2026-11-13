import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/player_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      context.go('/login');
      return;
    }
    try {
      final profile = await PlayerRepository(client).getMyProfile();
      if (!mounted) return;
      context.go(profile?.factionId == null ? '/faction' : '/home');
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.shield_moon_outlined, size: 76, color: Color(0xFF78945E)),
      const SizedBox(height: 18),
      Text('PROTOCOLO Z', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 4)),
      const SizedBox(height: 8),
      const Text('SOBREVIVA. COOPERE. RESISTA.', style: TextStyle(color: Color(0xFFA6ADA7), letterSpacing: 2, fontSize: 10)),
      const SizedBox(height: 36),
      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
    ])),
  );
}
