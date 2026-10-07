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
    final rawUnreadCount = json['unread_count'];
    if (rawItems is! List || rawUnreadCount is! int || rawUnreadCount < 0) {
      throw const FormatException('Invalid notifications response.');
    }

    final items = <MobileNotification>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) {
        throw const FormatException('Invalid notification item.');
      }
      items.add(
        MobileNotification.fromJson(Map<String, dynamic>.from(rawItem)),
      );
    }

    return MobileNotificationPage(
      notifications: items,
      unreadCount: rawUnreadCount,
    );
  }
}
