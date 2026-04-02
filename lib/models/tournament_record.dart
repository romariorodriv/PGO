class TournamentRecord {
  const TournamentRecord({
    required this.id,
    required this.title,
    required this.tournamentType,
    required this.playerCapacity,
    required this.modality,
    required this.format,
    required this.location,
    required this.address,
    required this.city,
    required this.district,
    required this.startsAt,
    required this.prize,
    required this.entryFee,
    required this.category,
    required this.status,
    required this.description,
    required this.photoUrl,
    required this.createdById,
    required this.createdByName,
    required this.registrationsCount,
    required this.registeredPlayers,
    required this.registrationUserIds,
  });

  final String id;
  final String title;
  final String tournamentType;
  final int playerCapacity;
  final String modality;
  final String format;
  final String location;
  final String? address;
  final String city;
  final String district;
  final DateTime startsAt;
  final String prize;
  final int entryFee;
  final String category;
  final String status;
  final String? description;
  final String? photoUrl;
  final String? createdById;
  final String? createdByName;
  final int registrationsCount;
  final List<TournamentPlayer> registeredPlayers;
  final List<String> registrationUserIds;

  factory TournamentRecord.fromJson(Map<String, dynamic> json) {
    final rawRegistrations = (json['registrations'] as List<dynamic>?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    final registeredPlayers = _extractRegisteredPlayers(rawRegistrations);
    final registrationUserIds = _extractRegistrationUserIds(rawRegistrations);
    final registrationsCount = registeredPlayers.isNotEmpty
        ? registeredPlayers.length
        : rawRegistrations.length;

    return TournamentRecord(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      tournamentType: json['tournamentType'] as String? ?? '',
      playerCapacity: (json['playerCapacity'] as num?)?.toInt() ?? 0,
      modality: json['modality'] as String? ?? '',
      format: json['format'] as String? ?? '',
      location: json['location'] as String? ?? '',
      address: json['address'] as String?,
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      startsAt: DateTime.parse(json['startsAt'] as String),
      prize: json['prize'] as String? ?? '',
      entryFee: (json['entryFee'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? '',
      status: json['status'] as String? ?? '',
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdById: (json['createdBy'] as Map<String, dynamic>?)?['id'] as String?,
      createdByName:
          (json['createdBy'] as Map<String, dynamic>?)?['name'] as String?,
      registrationsCount: registrationsCount,
      registeredPlayers: registeredPlayers,
      registrationUserIds: registrationUserIds,
    );
  }

  static List<String> _extractRegistrationUserIds(
    List<Map<String, dynamic>> registrations,
  ) {
    final ids = <String>{};

    for (final registration in registrations) {
      final userId = registration['userId'] as String?;
      final partnerUserId = registration['partnerUserId'] as String?;

      if (userId != null && userId.isNotEmpty) {
        ids.add(userId);
      }
      if (partnerUserId != null && partnerUserId.isNotEmpty) {
        ids.add(partnerUserId);
      }
    }

    return ids.toList();
  }

  static List<TournamentPlayer> _extractRegisteredPlayers(
    List<Map<String, dynamic>> registrations,
  ) {
    final playersById = <String, TournamentPlayer>{};

    for (final registration in registrations) {
      final userJson = registration['user'] as Map<String, dynamic>?;
      final partnerJson = registration['partnerUser'] as Map<String, dynamic>?;

      if (userJson != null) {
        final player = TournamentPlayer.fromJson(userJson);
        if (player.id.isNotEmpty) {
          playersById[player.id] = player;
        }
      }

      if (partnerJson != null) {
        final partner = TournamentPlayer.fromJson(partnerJson);
        if (partner.id.isNotEmpty) {
          playersById[partner.id] = partner;
        }
      }
    }

    return playersById.values.toList();
  }
}

class TournamentPlayer {
  const TournamentPlayer({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.category,
    required this.rankingPosition,
    required this.preferredClub,
  });

  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? category;
  final int rankingPosition;
  final String? preferredClub;

  factory TournamentPlayer.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? json;
    final profile = user['profile'] as Map<String, dynamic>?;

    return TournamentPlayer(
      id: user['id'] as String? ?? '',
      name: user['name'] as String? ?? '',
      email: user['email'] as String?,
      photoUrl: profile?['photoUrl'] as String?,
      category: profile?['category'] as String?,
      rankingPosition: (profile?['rankingPosition'] as num?)?.toInt() ?? 0,
      preferredClub: profile?['preferredClub'] as String?,
    );
  }
}
