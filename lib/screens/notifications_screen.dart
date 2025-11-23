import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  final int currentUserId;
  const NotificationsScreen({super.key, required this.currentUserId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    final n = await NotificationService.instance.getNotificationsByRecipient(widget.currentUserId);
    setState(() {
      _notifications = n;
      _loading = false;
    });
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.idNotification == null) return;
    await NotificationService.instance.markAsRead(n.idNotification!);
    await _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), backgroundColor: AppTheme.primaryBlue),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final n = _notifications[index];
                    return ListTile(
                      tileColor: n.isRead ? null : AppTheme.primaryBlue.withOpacity(0.06),
                      title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.body),
                          const SizedBox(height: 6),
                          Text(n.createdAt.toLocal().toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () async => await _markRead(n),
                    );
                  },
                ),
    );
  }
}
