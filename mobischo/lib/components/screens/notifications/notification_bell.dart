import 'package:flutter/material.dart';
import 'package:mobischo/l10n/ui_text.dart';
import 'package:mobischo/utils/custom_theme.dart';

class NotificationBell extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onPressed;

  const NotificationBell({
    Key? key,
    required this.unreadCount,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: uiText(context, 'notificationBellTooltip'),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 3,
              top: 4,
              child: Icon(
                Icons.notifications_none,
                color: CustomTheme.blue,
                size: 28,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -3,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
