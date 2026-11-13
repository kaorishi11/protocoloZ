import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player_profile.dart';

class PlayerRepository {
  final SupabaseClient client;
  PlayerRepository(this.client);

  Future<PlayerProfile?> getMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    return row == null ? null : PlayerProfile.fromMap(row);
  }

  Future<List<Map<String, dynamic>>> getFactions() async =>
      client.from('factions').select().order('name');

  Future<void> chooseFaction(String factionId) async {
    await client.rpc('choose_faction', params: {'p_faction_id': factionId});
  }

  Future<void> signOut() => client.auth.signOut();
}
