import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  const NotificationsScreen({super.key});

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
      body: 'Learn 5 new words today and keep your streak alive! Today\'s theme: Business English.',
      time: 'Just now',
      unread: true,
    ),
    NotificationItem(
      id: 2,
      icon: Icons.bolt,
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFFFBEB),
      title: 'Grammar Quiz Ready',
      body: 'A new grammar quiz is waiting for you. Test your knowledge of present perfect tense.',
      time: '2h ago',
      unread: true,
    ),
    NotificationItem(
      id: 3,
      icon: Icons.emoji_events,
      color: Color(0xFF10B981),
      bg: Color(0xFFD1FAE5),
      title: '12-Day Streak! 🎉',
      body: 'Amazing! You\'ve studied English for 12 days in a row. Keep it up — you\'re on fire!',
      time: 'Yesterday',
      unread: false,
    ),
    NotificationItem(
      id: 4,
      icon: Icons.notifications,
      color: Color(0xFF0891B2),
      bg: Color(0xFFECFEFF),
      title: 'New AI Feature Available',
      body: 'Try the new pronunciation guide in AI Chat. Just type any word and ask for pronunciation help.',
      time: '2 days ago',
      unread: false,
    ),
    NotificationItem(
      id: 5,
      icon: Icons.book,
      color: Color(0xFFEC4899),
      bg: Color(0xFFFDF2F8),
      title: 'Word of the Day',
      body: 'Today\'s word is \'Eloquent\'. Do you know what it means? Tap to find out!',
      time: '3 days ago',
      unread: false,
    ),
    NotificationItem(
      id: 6,
      icon: Icons.emoji_events,
      color: Color(0xFF4F46E5),
      bg: Color(0xFFEEF0FF),
      title: 'You learned 50 words!',
      body: 'Milestone reached: 50 vocabulary words learned. You\'ve unlocked the \'Word Explorer\' badge.',
      time: '1 week ago',
      unread: false,
    ),
  ];

  late List<NotificationItem> _list;

  @override
  void initState() {
    super.initState();
    _list = List.from(_notifications);
  }

  void _markAllRead() {
    setState(() {
      _list = _list.map((n) {
        return NotificationItem(
          id: n.id,
          icon: n.icon,
          color: n.color,
          bg: n.bg,
          title: n.title,
          body: n.body,
          time: n.time,
          unread: false,
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5);
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    final unreadCount = _list.where((n) => n.unread).length;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unreadCount > 0 ? '$unreadCount new notifications' : 'You\'re all caught up',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: GestureDetector(
                  onTap: _markAllRead,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.done_all, color: Color(0xFF4F46E5), size: 16),
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
              itemCount: _list.length,
              itemBuilder: (context, index) {
                final n = _list[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: n.unread ? const Color(0xFFEEF0FF) : Colors.white,
                    border: Border.all(
                      color: n.unread ? const Color(0xFF4F46E5).withOpacity(0.18) : cardBorderColor,
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
