class MobileNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final bool isRead;

  const MobileNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    required this.isRead,
  });

  factory MobileNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawCreatedAt = json['created_at'];

    return MobileNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: rawData is Map<String, dynamic>
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{},
      createdAt: rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt)?.toLocal()
          : null,
      isRead: json['is_read'] == true || json['read_at'] != null,
    );
  }
}

class MobileNotificationPage {
  final List<MobileNotification> notifications;
  final int unreadCount;

  const MobileNotificationPage({
    required this.notifications,
    required this.unreadCount,
  });

  factory MobileNotificationPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(MobileNotification.fromJson)
            .toList()
        : <MobileNotification>[];

    return MobileNotificationPage(
      notifications: items,
      unreadCount: _notificationInt(json['unread_count']),
    );
  }
}

int _notificationInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
