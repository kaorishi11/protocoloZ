import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/game_repository.dart';
import '../../widgets/stat_panel.dart';
import '../../widgets/faction_badge.dart';
import '../../widgets/horde_alert_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await GameRepository(Supabase.instance.client).dashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final data = _data;
    final faction = data?['factions'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: const Text('CENTRAL DE SOBREVIVÊNCIA'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(18), children: [
        Row(children: [
          FactionBadge(symbol: faction?['symbol'] ?? '⚑', colorHex: faction?['color'] ?? '#78945E'),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BEM-VINDO, ${data?['nickname'] ?? 'SOBREVIVENTE'}', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5)),
            Text(faction?['name'] ?? 'Facção', style: const TextStyle(color: Color(0xFFA6ADA7))),
          ])),
        ]),
        const SizedBox(height: 22),
        StatPanel(icon: Icons.military_tech_outlined, label: 'REPUTAÇÃO', value: '${data?['reputation'] ?? 0} XP'),
        const SizedBox(height: 12),
        const HordeAlertBanner(message: 'Mantenha atenção aos sinais de atividade nas proximidades.'),
        const SizedBox(height: 22),
        Text('SUA JORNADA', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        _ActionTile(icon: Icons.explore_outlined, title: 'Iniciar expedição', subtitle: 'Procure recursos fora do abrigo', onTap: () => context.go('/expeditions')),
        _ActionTile(icon: Icons.inventory_2_outlined, title: 'Consultar inventário', subtitle: 'Confira seus suprimentos', onTap: () => context.go('/inventory')),
        _ActionTile(icon: Icons.map_outlined, title: 'Mapa e abrigos', subtitle: 'Em desenvolvimento nesta etapa', onTap: () => context.go('/map')),
      ])),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: const Color(0xFF9AB47C), size: 28), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}
