import 'package:supabase_flutter/supabase_flutter.dart';

class GameRepository {
  final SupabaseClient client;
  GameRepository(this.client);

  Future<List<Map<String, dynamic>>> inventory() async {
    final rows = await client.from('inventory')
        .select('quantity, items(id,name,category,icon)')
        .order('item_id');
    return rows;
  }

  Future<List<Map<String, dynamic>>> expeditionTypes() async =>
      client.from('expedition_types').select().eq('active', true).order('duration_seconds');

  Future<Map<String, dynamic>?> activeExpedition() async =>
      client.from('expeditions').select('*, expedition_types(name)')
          .eq('status', 'in_progress').maybeSingle();

  Future<void> startExpedition(String typeId) async {
    await client.rpc('start_expedition', params: {'p_expedition_type_id': typeId});
  }

  Future<void> claimExpedition(String expeditionId) async {
    await client.rpc('claim_expedition', params: {'p_expedition_id': expeditionId});
  }

  Future<Map<String, dynamic>> dashboard() async {
    final profile = await client.from('profiles')
        .select('nickname,reputation,faction_id,factions(name,symbol,color)')
        .single();
    return profile;
  }
}
