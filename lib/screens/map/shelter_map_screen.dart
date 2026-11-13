import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/location_repository.dart';
import '../../repositories/device_media_repository.dart';
import '../../repositories/shelter_repository.dart';
import '../../widgets/image_source_sheet.dart';

class ShelterMapScreen extends StatefulWidget {
  const ShelterMapScreen({super.key});
  @override
  State<ShelterMapScreen> createState() => _ShelterMapScreenState();
}
class _ShelterMapScreenState extends State<ShelterMapScreen> {
  final _map = MapController();
  final _location = LocationRepository();
  late final _client = Supabase.instance.client;
  late final _repo = ShelterRepository(_client);
  late final _media = DeviceMediaRepository(_client);
  static const _initial = LatLng(-23.1144, -45.7078);
  LatLng _picked = _initial;
  LatLng? _me;
  List<Map<String, dynamic>> _shelters = [];
  XFile? _photo;
  bool _loading = true, _saving = false;

  @override
  void initState() { super.initState(); _load(); _locate(); }

  Future<void> _load() async {
    try {
      final rows = await _repo.listVisible();
      if (mounted) setState(() { _shelters = rows; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar abrigos: $e'))); }
    }
  }

  Future<void> _locate() async {
    try {
      final Position? p = await _location.currentPosition();
      if (!mounted) return;
      if (p == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS indisponível ou permissão negada. Toque no mapa para escolher manualmente.')));
        return;
      }
      final point = LatLng(p.latitude, p.longitude);
      setState(() { _me = point; _picked = point; });
      _map.move(point, 15);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível obter o GPS. Marque o local manualmente no mapa.')));
    }
  }

  Future<void> _pickPhoto() async {
    final source = await ImageSourceSheet.show(context);
    if (source == null) return;
    try {
      final file = await _media.pickImage(source);
      if (file != null && mounted) setState(() => _photo = file);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao selecionar foto: $e')));
    }
  }

  Future<void> _create() async {
    final name = TextEditingController(), desc = TextEditingController(), cap = TextEditingController(text: '10');
    String visibility = 'public';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
      title: const Text('Cadastrar abrigo'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 8),
        TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
        const SizedBox(height: 8),
        TextField(controller: cap, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacidade')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: visibility, decoration: const InputDecoration(labelText: 'Visibilidade'), items: const [
          DropdownMenuItem(value: 'public', child: Text('Público')),
          DropdownMenuItem(value: 'faction', child: Text('Minha facção')),
        ], onChanged: (v) => setDialog(() => visibility = v ?? 'public')),
        OutlinedButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.add_a_photo_outlined), label: Text(_photo == null ? 'Adicionar foto' : 'Foto selecionada')),
        Text('Coordenadas: ${_picked.latitude.toStringAsFixed(5)}, ${_picked.longitude.toStringAsFixed(5)}', style: Theme.of(ctx).textTheme.bodySmall),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
      ],
    )));
    if (ok != true) return;
    final capacity = int.tryParse(cap.text);
    if (name.text.trim().isEmpty || desc.text.trim().isEmpty || capacity == null || capacity < 1) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos corretamente.')));
      return;
    }
    setState(() => _saving = true);
    try {
      String? photoUrl;
      if (_photo != null) {
        final uid = _client.auth.currentUser!.id;
        final ext = _photo!.name.contains('.') ? _photo!.name.split('.').last.toLowerCase() : 'jpg';
        photoUrl = await _media.upload(file: _photo!, bucket: 'shelter-photos', path: '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext');
      }
      await _repo.create(name: name.text.trim(), description: desc.text.trim(), capacity: capacity,
        latitude: _picked.latitude, longitude: _picked.longitude, visibility: visibility, photoUrl: photoUrl);
      _photo = null;
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrigo cadastrado. +15 de reputação.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao cadastrar abrigo: $e')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      ..._shelters.map((s) => Marker(point: LatLng((s['latitude'] as num).toDouble(), (s['longitude'] as num).toDouble()), width: 42, height: 42,
        child: IconButton(padding: EdgeInsets.zero, onPressed: () => _details(s), icon: const Icon(Icons.home_work, color: Color(0xFF9AB47C), size: 34)))),
      if (_me != null) Marker(point: _me!, width: 30, height: 30, child: const Icon(Icons.my_location, color: Colors.lightBlueAccent)),
      Marker(point: _picked, width: 32, height: 32, child: const Icon(Icons.location_pin, color: Colors.orangeAccent, size: 32)),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('MAPA E ABRIGOS'), actions: [IconButton(onPressed: _locate, icon: const Icon(Icons.my_location), tooltip: 'Minha localização')]),
      body: Stack(children: [
        FlutterMap(mapController: _map, options: MapOptions(initialCenter: _initial, initialZoom: 13, onTap: (_, point) => setState(() => _picked = point)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.protocolo_z'),
            MarkerLayer(markers: markers),
            const RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
          ]),
        Positioned(top: 12, left: 12, right: 12, child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('Toque no mapa para marcar o abrigo. ${_shelters.length} abrigo(s) visível(is).')))),
        Positioned(right: 16, bottom: 18, child: FloatingActionButton.extended(onPressed: _saving ? null : _create,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add_home_work),
          label: Text(_saving ? 'Salvando...' : 'Cadastrar abrigo'))),
        if (_loading) const Positioned(top: 76, right: 18, child: CircularProgressIndicator()),
      ]),
    );
  }

  void _details(Map<String, dynamic> s) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF19231D), builder: (_) => Padding(
      padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s['name'], style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8), Text(s['description'] ?? ''),
        const SizedBox(height: 8), Text('Capacidade: ${s['capacity']}'),
        Text('Status: ${s['status'] == 'safe' ? 'Seguro' : 'Comprometido'}'),
        Text('Visibilidade: ${s['visibility'] == 'public' ? 'Público' : 'Facção'}'),
        if (s['photo_url'] != null) ...[const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(s['photo_url'], height: 150, width: double.infinity, fit: BoxFit.cover))],
      ]),
    ));
  }
}
