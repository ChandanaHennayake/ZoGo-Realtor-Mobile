import 'package:flutter/material.dart';
import '../../data/services/user_notification_service.dart';
import '../../models/user_notification_model.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final UserNotificationService _service = UserNotificationService();
  bool _isLoading = true;
  List<UserNotificationModel> _notifications = [];

  static const Color darkBackground = Color(0xFF0A0D14);
  static const Color surfaceElevated = Color(0xFF131926);
  static const Color primaryCyan = Color(0xFF00C6D4);
  static const Color textMuted = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final list = await _service.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final success = await _service.markAllAsRead();
    if (success && mounted) {
      setState(() {
        _notifications = _notifications
            .map((n) => UserNotificationModel(
                  id: n.id,
                  userId: n.userId,
                  type: n.type,
                  title: n.title,
                  message: n.message,
                  referenceId: n.referenceId,
                  referenceType: n.referenceType,
                  isRead: true,
                  readAt: DateTime.now(),
                  createdAt: n.createdAt,
                ))
            .toList();
      });
    }
  }

  Future<void> _markSingleRead(UserNotificationModel item) async {
    if (item.isRead) return;
    await _service.markAsRead(item.id);
    if (mounted) {
      setState(() {
        final idx = _notifications.indexWhere((x) => x.id == item.id);
        if (idx != -1) {
          _notifications[idx] = UserNotificationModel(
            id: item.id,
            userId: item.userId,
            type: item.type,
            title: item.title,
            message: item.message,
            referenceId: item.referenceId,
            referenceType: item.referenceType,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: item.createdAt,
          );
        }
      });
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PROPERTY_APPROVED':
      case 'PROPERTY_STATUS':
        return Icons.verified_outlined;
      case 'OFFER_RECEIVED':
      case 'OFFER_COUNTERED':
      case 'OFFER_ACCEPTED':
        return Icons.handshake_outlined;
      case 'TRANSACTION_INITIATED':
      case 'TRANSACTION_SETTLED':
      case 'TRANSACTION_DEED_SIGNED':
        return Icons.gavel_outlined;
      case 'VISIT_REQUESTED':
      case 'VISIT_CONFIRMED':
        return Icons.calendar_month_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: darkBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryCyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: _markAllRead,
                    style: TextButton.styleFrom(
                      foregroundColor: primaryCyan,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Mark all read'),
                  ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: primaryCyan),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.notifications_off_outlined, color: textMuted, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'No notifications yet',
                              style: TextStyle(color: textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final item = _notifications[index];
                          return InkWell(
                            onTap: () => _markSingleRead(item),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: item.isRead ? surfaceElevated : surfaceElevated.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: item.isRead
                                      ? Colors.white10
                                      : primaryCyan.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: item.isRead
                                          ? Colors.white10
                                          : primaryCyan.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getTypeIcon(item.type),
                                      color: item.isRead ? textMuted : primaryCyan,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.message,
                                          style: const TextStyle(
                                            color: textMuted,
                                            fontSize: 12,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year} ${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: Colors.white30,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!item.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4, left: 6),
                                      decoration: const BoxDecoration(
                                        color: primaryCyan,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
