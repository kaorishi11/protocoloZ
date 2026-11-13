import 'package:supabase_flutter/supabase_flutter.dart';
class ShelterRepository {
  ShelterRepository(this.client);
  final SupabaseClient client;
  Future<List<Map<String, dynamic>>> listVisible() async {
    final rows = await client.from('shelters').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
  Future<void> create({required String name, required String description, required int capacity, required double latitude, required double longitude, required String visibility, String? photoUrl}) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Sessão expirada.');
    final profile = await client.from('profiles').select('faction_id').eq('id', user.id).single();
    await client.from('shelters').insert({
      'author_id': user.id, 'faction_id': profile['faction_id'],
      'name': name, 'description': description, 'capacity': capacity,
      'latitude': latitude, 'longitude': longitude, 'visibility': visibility, 'photo_url': photoUrl,
    });
  }
}
