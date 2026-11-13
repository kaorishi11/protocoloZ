import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/device_media_repository.dart';
import '../../widgets/image_source_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final client = Supabase.instance.client;
  late final media = DeviceMediaRepository(client);
  String? avatarUrl;
  bool loading = true;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final row = await client.from('profiles').select('avatar_url').single();
      if (mounted) setState(() { avatarUrl = row['avatar_url']; loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _changeAvatar() async {
    final source = await ImageSourceSheet.show(context);
    if (source == null) return;
    try {
      final XFile? file = await media.pickImage(source);
      if (file == null) return;
      setState(() => uploading = true);
      final uid = client.auth.currentUser!.id;
      final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
      final url = await media.upload(
        file: file,
        bucket: 'avatars',
        path: '$uid/avatar.$ext',
      );
      await client.rpc('set_my_avatar_url', params: {'p_avatar_url': url});
      if (mounted) setState(() => avatarUrl = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível atualizar o avatar: $e')));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = client.auth.currentUser;
    final nickname = user?.userMetadata?['nickname'] ?? 'Sobrevivente';
    return Scaffold(
      appBar: AppBar(title: const Text('PERFIL')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Center(child: Stack(children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFF29382D),
            backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
            child: avatarUrl == null ? const Icon(Icons.person, size: 48) : null,
          ),
          Positioned(right: 0, bottom: 0, child: IconButton.filled(
            onPressed: uploading ? null : _changeAvatar,
            icon: uploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
          )),
        ])),
        const SizedBox(height: 14),
        Text(nickname, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        Text(user?.email ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA6ADA7))),
        if (loading) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
        const SizedBox(height: 28),
        FilledButton.tonalIcon(
          onPressed: () async {
            await client.auth.signOut();
            if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
          },
          icon: const Icon(Icons.logout),
          label: const Text('SAIR DA CONTA'),
        ),
      ]),
    );
  }
}
