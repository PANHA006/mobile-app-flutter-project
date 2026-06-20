import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // To access isFirebaseInitialized

class NotificationItem {
  final int id;
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String body;
  final String time;
  final bool unread;

  const NotificationItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });
}

class NotificationsScreen extends StatefulWidget {
  final Map<String, String> user;
  final Function(int) onNavigate;

  const NotificationsScreen({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = const [
    NotificationItem(
      id: 1,
      icon: Icons.book,
      color: Color(0xFF4F46E5),
      bg: Color(0xFFEEF0FF),
      title: 'Daily Vocabulary Challenge',
      body:
          'Learn 5 new words today and keep your streak alive! Today\'s theme: Business English.',
      time: 'Just now',
      unread: true,
    ),
    NotificationItem(
      id: 2,
      icon: Icons.bolt,
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFFFBEB),
      title: 'Grammar Quiz Ready',
      body:
          'A new grammar quiz is waiting for you. Test your knowledge of present perfect tense.',
      time: '2h ago',
      unread: true,
    ),
    NotificationItem(
      id: 3,
      icon: Icons.emoji_events,
      color: Color(0xFF10B981),
      bg: Color(0xFFD1FAE5),
      title: '12-Day Streak! 🎉',
      body:
          'Amazing! You\'ve studied English for 12 days in a row. Keep it up — you\'re on fire!',
      time: 'Yesterday',
      unread: false,
    ),
    NotificationItem(
      id: 4,
      icon: Icons.notifications,
      color: Color(0xFF0891B2),
      bg: Color(0xFFECFEFF),
      title: 'New AI Feature Available',
      body:
          'Try the new pronunciation guide in AI Chat. Just type any word and ask for pronunciation help.',
      time: '2 days ago',
      unread: false,
    ),
    NotificationItem(
      id: 5,
      icon: Icons.book,
      color: Color(0xFFEC4899),
      bg: Color(0xFFFDF2F8),
      title: 'Word of the Day',
      body:
          'Today\'s word is \'Eloquent\'. Do you know what it means? Tap to find out!',
      time: '3 days ago',
      unread: false,
    ),
    NotificationItem(
      id: 6,
      icon: Icons.emoji_events,
      color: Color(0xFF4F46E5),
      bg: Color(0xFFEEF0FF),
      title: 'You learned 50 words!',
      body:
          'Milestone reached: 50 vocabulary words learned. You\'ve unlocked the \'Word Explorer\' badge.',
      time: '1 week ago',
      unread: false,
    ),
  ];

  List<NotificationItem> _getParsedNotifications() {
    try {
      final box = Hive.box('vocabulary_box');
      final List<dynamic> rawList = box.get('notifications_list') ?? [];
      
      if (rawList.isEmpty) {
        final defaultNotifs = _notifications.map((n) => {
          'id': n.id,
          'icon': n.icon == Icons.book ? 'welcome' : (n.icon == Icons.emoji_events ? 'congrats' : (n.icon == Icons.bolt ? 'level' : 'profile')),
          'title': n.title,
          'body': n.body,
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'unread': n.unread,
        }).toList();
        box.put('notifications_list', defaultNotifs);
        return _notifications;
      }
      
      return rawList.map((item) {
        final Map<String, dynamic> m = Map<String, dynamic>.from(item);
        final String iconName = m['icon'] ?? 'welcome';
        
        IconData iconData = Icons.notifications;
        Color color = const Color(0xFF0891B2);
        Color bg = const Color(0xFFECFEFF);
        
        if (iconName == 'welcome') {
          iconData = Icons.waving_hand_rounded;
          color = const Color(0xFF4F46E5);
          bg = const Color(0xFFEEF0FF);
        } else if (iconName == 'congrats') {
          iconData = Icons.emoji_events_rounded;
          color = const Color(0xFF10B981);
          bg = const Color(0xFFD1FAE5);
        } else if (iconName == 'level') {
          iconData = Icons.trending_up_rounded;
          color = const Color(0xFFF59E0B);
          bg = const Color(0xFFFFFBEB);
        } else if (iconName == 'profile') {
          iconData = Icons.person_rounded;
          color = const Color(0xFF0891B2);
          bg = const Color(0xFFECFEFF);
        }
        
        String timeStr = 'Just now';
        if (m['timestamp'] != null) {
          try {
            final dt = DateTime.parse(m['timestamp']);
            final diff = DateTime.now().difference(dt);
            if (diff.inMinutes < 1) {
              timeStr = 'Just now';
            } else if (diff.inMinutes < 60) {
              timeStr = '${diff.inMinutes}m ago';
            } else if (diff.inHours < 24) {
              timeStr = '${diff.inHours}h ago';
            } else {
              timeStr = '${diff.inDays} days ago';
            }
          } catch (e) { debugPrint('Error parsing notification timestamp: $e'); }
        }
        
        return NotificationItem(
          id: m['id'] ?? 0,
          icon: iconData,
          color: color,
          bg: bg,
          title: m['title'] ?? '',
          body: m['body'] ?? '',
          time: timeStr,
          unread: m['unread'] ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _markAllRead() {
    try {
      final box = Hive.box('vocabulary_box');
      final List<dynamic> rawList = box.get('notifications_list') ?? [];
      final List<Map<String, dynamic>> list = rawList.map((e) => Map<String, dynamic>.from(e)).toList();
      
      for (var item in list) {
        item['unread'] = false;
      }
      
      box.put('notifications_list', list);
      
      final uid = widget.user['uid'];
      if (uid != null && isFirebaseInitialized) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'notifications_list': list,
        }).catchError((e) { debugPrint('Error syncing notifications to Firestore: $e'); });
      }
    } catch (e) { debugPrint('Error marking all notifications as read: $e'); }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5);
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    final notificationList = _getParsedNotifications();
    final unreadCount = notificationList.where((n) => n.unread).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: const Color(0xFFEEF0FF),
              ),
              child: const Icon(Icons.notifications,
                  color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  unreadCount > 0
                      ? '$unreadCount new notifications'
                      : 'You\'re all caught up',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(
                  right:
                      18.0), // give it regular margin since it is the last item
              child: Center(
                child: GestureDetector(
                  onTap: _markAllRead,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.done_all,
                            color: Color(0xFF4F46E5), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Mark all read',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF4F46E5),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // List of notifications
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notificationList.length,
              itemBuilder: (context, index) {
                final n = notificationList[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: n.unread ? const Color(0xFFEEF0FF) : Colors.white,
                    border: Border.all(
                      color: n.unread
                          ? const Color(0xFF4F46E5).withOpacity(0.18)
                          : cardBorderColor,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: n.bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(n.icon, color: n.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFF0F0E2A),
                                    ),
                                  ),
                                ),
                                if (n.unread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6B6B8A),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.time,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6B6B8A),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
