import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/game_repository.dart';
import '../../widgets/item_tile.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _filter = 'todos';

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final rows = await GameRepository(Supabase.instance.client).inventory();
      if (mounted) setState(() { _items = rows; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((row) {
      final item = row['items'] as Map<String, dynamic>?;
      return _filter == 'todos' || item?['category'] == _filter;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('INVENTÁRIO')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Column(children: [
        SizedBox(height: 58, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          for (final category in ['todos', 'agua', 'comida', 'medicamentos', 'ferramentas', 'combustivel'])
            Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(label: Text(category.toUpperCase()), selected: _filter == category, onSelected: (_) => setState(() => _filter = category))),
        ])),
        Expanded(child: filtered.isEmpty
          ? const Center(child: Text('Sua mochila está vazia. Faça uma expedição para encontrar suprimentos.'))
          : ListView.separated(itemCount: filtered.length, separatorBuilder: (_, __) => const Divider(height: 1), itemBuilder: (_, i) {
              final row = filtered[i];
              final item = row['items'] as Map<String, dynamic>;
              return ItemTile(name: item['name'], category: item['category'], icon: item['icon'] ?? '📦', quantity: row['quantity']);
            })),
      ]),
    );
  }
}
