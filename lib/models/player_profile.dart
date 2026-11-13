class PlayerProfile {
  final String id;
  final String nickname;
  final String? factionId;
  final int reputation;
  final String? avatarUrl;

  const PlayerProfile({
    required this.id,
    required this.nickname,
    required this.factionId,
    required this.reputation,
    required this.avatarUrl,
  });

  factory PlayerProfile.fromMap(Map<String, dynamic> map) => PlayerProfile(
        id: map['id'] as String,
        nickname: map['nickname'] as String,
        factionId: map['faction_id'] as String?,
        reputation: (map['reputation'] as num?)?.toInt() ?? 0,
        avatarUrl: map['avatar_url'] as String?,
      );
}
