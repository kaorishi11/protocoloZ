import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/game_repository.dart';
import '../../widgets/countdown_timer.dart';

class ExpeditionsScreen extends StatefulWidget {
  const ExpeditionsScreen({super.key});
  @override
  State<ExpeditionsScreen> createState() => _ExpeditionsScreenState();
}

class _ExpeditionsScreenState extends State<ExpeditionsScreen> {
  List<Map<String, dynamic>> _types = [];
  Map<String, dynamic>? _active;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final repo = GameRepository(Supabase.instance.client);
      final results = await Future.wait([repo.expeditionTypes(), repo.activeExpedition()]);
      if (mounted) setState(() { _types = results[0] as List<Map<String, dynamic>>; _active = results[1] as Map<String, dynamic>?; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _start(String id) async {
    setState(() => _busy = true);
    try { await GameRepository(Supabase.instance.client).startExpedition(id); await _load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível iniciar: $e'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _claim() async {
    if (_active == null) return;
    setState(() => _busy = true);
    try {
      await GameRepository(Supabase.instance.client).claimExpedition(_active!['id']);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recompensas adicionadas ao inventário!')));
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('A expedição ainda não pode ser concluída: $e'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('EXPEDIÇÕES')),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(18), children: [
      if (_active != null) Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('EXPEDIÇÃO EM ANDAMENTO', style: TextStyle(color: Color(0xFF9AB47C), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(_active!['expedition_types']?['name'] ?? 'Área desconhecida', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        CountdownTimer(endsAt: DateTime.parse(_active!['ends_at']).toLocal()),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _claim, child: const Text('RESGATAR RECOMPENSAS'))),
      ]))),
      Text(_active == null ? 'ESCOLHA UM DESTINO' : 'OUTROS DESTINOS', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      ..._types.map((t) => Card(child: ListTile(
        leading: const Icon(Icons.explore_outlined, color: Color(0xFF9AB47C)),
        title: Text(t['name']),
        subtitle: Text('Duração: ${(t['duration_seconds'] / 60).ceil()} min • Risco: ${t['risk']}'),
        trailing: _active == null ? IconButton(onPressed: _busy ? null : () => _start(t['id']), icon: const Icon(Icons.play_arrow)) : const Icon(Icons.lock_outline),
      ))),
    ]),
  );
}
