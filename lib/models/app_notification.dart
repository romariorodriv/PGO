class AppNotificationResponse {
  const AppNotificationResponse({
    required this.unreadCount,
    required this.notifications,
  });

  final int unreadCount;
  final List<PgoAppNotification> notifications;

  factory AppNotificationResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['notifications'];
    return AppNotificationResponse(
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      notifications: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(PgoAppNotification.fromJson)
              .toList()
          : const [],
    );
  }
}

class PgoAppNotification {
  const PgoAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory PgoAppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return PgoAppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'GENERAL',
      title: json['title']?.toString() ?? 'Notificación PGO',
      body: json['body']?.toString() ?? '',
      data: rawData is Map<String, dynamic> ? rawData : const {},
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      readAt: DateTime.tryParse(json['readAt']?.toString() ?? '')?.toLocal(),
    );
  }

  PgoAppNotification copyWith({DateTime? readAt}) {
    return PgoAppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
