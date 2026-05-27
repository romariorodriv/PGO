class OpenMatchAlert {
  const OpenMatchAlert({
    required this.id,
    required this.category,
    required this.format,
    required this.startsAt,
    required this.club,
    required this.district,
    required this.courtStatus,
    required this.missingPlayers,
    required this.totalMissingPlayers,
    required this.joinedPlayers,
    required this.costPerPerson,
    required this.paymentLabel,
    required this.status,
    required this.isOrganizer,
    required this.hasJoined,
    required this.organizer,
    required this.participants,
    required this.coordinationUpdates,
    required this.latestCoordinationByUser,
    this.comment,
  });

  final String id;
  final String category;
  final String format;
  final DateTime startsAt;
  final String club;
  final String district;
  final String courtStatus;
  final int missingPlayers;
  final int totalMissingPlayers;
  final int joinedPlayers;
  final int costPerPerson;
  final String paymentLabel;
  final String status;
  final bool isOrganizer;
  final bool hasJoined;
  final OpenMatchUser organizer;
  final List<OpenMatchUser> participants;
  final List<OpenMatchCoordinationUpdate> coordinationUpdates;
  final List<OpenMatchLatestCoordination> latestCoordinationByUser;
  final String? comment;

  factory OpenMatchAlert.fromJson(Map<String, dynamic> json) {
    return OpenMatchAlert(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      format: json['format'] as String? ?? '',
      startsAt: DateTime.parse(json['startsAt'] as String),
      club: json['club'] as String? ?? '',
      district: json['district'] as String? ?? '',
      courtStatus: json['courtStatus'] as String? ?? '',
      missingPlayers: (json['missingPlayers'] as num?)?.toInt() ?? 0,
      totalMissingPlayers: (json['totalMissingPlayers'] as num?)?.toInt() ?? 0,
      joinedPlayers: (json['joinedPlayers'] as num?)?.toInt() ?? 0,
      costPerPerson: (json['costPerPerson'] as num?)?.toInt() ?? 0,
      paymentLabel: json['paymentLabel'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      isOrganizer: json['isOrganizer'] as bool? ?? false,
      hasJoined: json['hasJoined'] as bool? ?? false,
      organizer: OpenMatchUser.fromJson(
        (json['organizer'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      participants: (json['participants'] as List<dynamic>? ?? const [])
          .map((item) =>
              OpenMatchUser.fromJson((item as Map).cast<String, dynamic>()))
          .toList(),
      coordinationUpdates:
          (json['coordinationUpdates'] as List<dynamic>? ?? const [])
              .map((item) => OpenMatchCoordinationUpdate.fromJson(
                  (item as Map).cast<String, dynamic>()))
              .toList(),
      latestCoordinationByUser:
          (json['latestCoordinationByUser'] as List<dynamic>? ?? const [])
              .map((item) => OpenMatchLatestCoordination.fromJson(
                  (item as Map).cast<String, dynamic>()))
              .toList(),
      comment: json['comment'] as String?,
    );
  }
}

class OpenMatchUser {
  const OpenMatchUser({
    required this.id,
    required this.name,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String? photoUrl;

  factory OpenMatchUser.fromJson(Map<String, dynamic> json) {
    return OpenMatchUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

class OpenMatchCoordinationUpdate {
  const OpenMatchCoordinationUpdate({
    required this.id,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.user,
  });

  final String id;
  final String status;
  final String message;
  final DateTime createdAt;
  final OpenMatchUser user;

  factory OpenMatchCoordinationUpdate.fromJson(Map<String, dynamic> json) {
    return OpenMatchCoordinationUpdate(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      user: OpenMatchUser.fromJson(
        (json['user'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }
}

class OpenMatchLatestCoordination {
  const OpenMatchLatestCoordination({
    required this.userId,
    required this.status,
    required this.message,
    required this.createdAt,
  });

  final String userId;
  final String status;
  final String message;
  final DateTime createdAt;

  factory OpenMatchLatestCoordination.fromJson(Map<String, dynamic> json) {
    return OpenMatchLatestCoordination(
      userId: json['userId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
