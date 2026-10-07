import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/models/mobile_notification.dart';
import 'package:mobischo/models/user.dart';
import 'package:mobischo/services/notification_inbox_service.dart';
import 'package:mobischo/utils/custom_theme.dart';

class NotificationListScreen extends StatefulWidget {
  final User user;
  final ValueChanged<int> onUnreadCountChanged;
  final Future<MobileNotificationPage> Function()? loadNotifications;

  const NotificationListScreen({
    Key? key,
    required this.user,
    required this.onUnreadCountChanged,
    this.loadNotifications,
  }) : super(key: key);

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  late Future<MobileNotificationPage> _notificationsFuture;
  List<MobileNotification> _notifications = <MobileNotification>[];
  int _unreadCount = 0;
  bool _isMarkingAllRead = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<MobileNotificationPage> _loadNotifications() async {
    final page =
        await (widget.loadNotifications ?? NotificationInboxService.load)();
    _notifications = page.notifications;
    _unreadCount = page.unreadCount;
    widget.onUnreadCountChanged(_unreadCount);
    return page;
  }

  Future<void> _reload() async {
    late Future<MobileNotificationPage> request;
    setState(() {
      _actionError = null;
      request = _loadNotifications();
      _notificationsFuture = request;
    });
    try {
      await request;
    } on Exception {
      // The FutureBuilder renders the request error state.
    }
  }

  Future<void> _markRead(MobileNotification notification) async {
    if (notification.isRead) return;
    try {
      final unreadCount = await NotificationInboxService.markAsRead(
        notification.id,
      );
      if (!mounted) return;

      setState(() {
        _unreadCount = unreadCount;
        _notifications = _notifications
            .map((item) => item.id == notification.id
                ? MobileNotification(
                    id: item.id,
                    title: item.title,
                    body: item.body,
                    data: item.data,
                    createdAt: item.createdAt,
                    isRead: true,
                  )
                : item)
            .toList();
        _actionError = null;
      });
      widget.onUnreadCountChanged(unreadCount);
    } on Exception catch (error) {
      debugPrint('Marking notification read failed (${error.runtimeType}).');
      if (mounted) {
        setState(() => _actionError = uiText(context, 'requestFailedTryAgain'));
      }
    }
  }

  Future<void> _markAllRead() async {
    if (_isMarkingAllRead || _unreadCount == 0) return;
    setState(() {
      _isMarkingAllRead = true;
      _actionError = null;
    });
    try {
      await NotificationInboxService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _unreadCount = 0;
        _notifications = _notifications
            .map((item) => MobileNotification(
                  id: item.id,
                  title: item.title,
                  body: item.body,
                  data: item.data,
                  createdAt: item.createdAt,
                  isRead: true,
                ))
            .toList();
      });
      widget.onUnreadCountChanged(0);
    } on Exception catch (error) {
      debugPrint(
          'Marking all notifications read failed (${error.runtimeType}).');
      if (mounted) {
        setState(() => _actionError = uiText(context, 'requestFailedTryAgain'));
      }
    } finally {
      if (mounted) setState(() => _isMarkingAllRead = false);
    }
  }

  String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) return '';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).add_jm().format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomTheme.grey,
      appBar: AppBar(
        backgroundColor: CustomTheme.blue,
        foregroundColor: Colors.white,
        title: Text(uiText(context, 'notifications')),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _isMarkingAllRead ? null : _markAllRead,
              child: _isMarkingAllRead
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      uiText(context, 'markAllNotificationsRead'),
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
        ],
      ),
      body: FutureBuilder<MobileNotificationPage>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Text(uiText(context, 'loadingEllipsis')));
          }
          if (snapshot.hasError) {
            return _MessageState(
              message: uiText(context, 'notificationLoadError'),
              actionLabel: uiText(context, 'retry'),
              onAction: _reload,
            );
          }

          if (_notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: CustomTheme.blue.withOpacity(0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      uiText(context, 'noNotifications'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      uiText(context, 'notificationsEmpty'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final isParent =
              widget.user.account_type.trim().toLowerCase() == 'parent';
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (_actionError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _actionError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ..._notifications.map((notification) {
                  final className = isParent
                      ? ''
                      : (notification.data['class_name']?.toString().trim() ??
                          '');
                  final dateLabel =
                      _formatDate(context, notification.createdAt);

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        notification.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: notification.isRead
                            ? Colors.grey
                            : CustomTheme.blue,
                      ),
                      title: Text(notification.title),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.body),
                            if (className.isNotEmpty &&
                                !isParent &&
                                !notification.body.contains(className))
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${uiText(context, 'notificationClass')}: $className',
                                ),
                              ),
                            if (dateLabel.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(dateLabel),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              uiText(
                                context,
                                notification.isRead
                                    ? 'notificationRead'
                                    : 'notificationUnread',
                              ),
                              style: TextStyle(
                                color: notification.isRead
                                    ? Colors.black54
                                    : CustomTheme.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      isThreeLine: true,
                      trailing: notification.isRead
                          ? null
                          : IconButton(
                              tooltip: uiText(context, 'markNotificationRead'),
                              onPressed: () => _markRead(notification),
                              icon: const Icon(Icons.mark_email_read_outlined),
                            ),
                      onTap: notification.isRead
                          ? null
                          : () => _markRead(notification),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
