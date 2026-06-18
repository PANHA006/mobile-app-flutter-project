import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../main.dart'; // To access isFirebaseInitialized

class AchievementItem {
  final String label;
  final String icon;
  final bool earned;

  const AchievementItem({
    required this.label,
    required this.icon,
    required this.earned,
  });
}

class ProfileScreen extends StatefulWidget {
  final Map<String, String> user;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _notifications = true;

  void _showEditProfileDialog() {
    final uid = widget.user['uid'];
    if (uid == null) return;
    
    final nameController = TextEditingController(text: widget.user['name']);
    String selectedLevel = widget.user['level'] ?? 'Beginner';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    style: GoogleFonts.inter(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: const [
                      DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                      DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedLevel = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    if (newName.isNotEmpty) {
                      // Update locally in widget.user
                      widget.user['name'] = newName;
                      widget.user['level'] = selectedLevel;
                      
                      if (isFirebaseInitialized) {
                        try {
                          await FirebaseFirestore.instance.collection('users').doc(uid).update({
                            'name': newName,
                            'level': selectedLevel,
                          });
                        } catch (_) {}
                      }
                      setState(() {});
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  final List<AchievementItem> _achievements = const [
    AchievementItem(label: 'First Word', icon: '📖', earned: true),
    AchievementItem(label: 'Word Explorer', icon: '🔍', earned: true),
    AchievementItem(label: 'Grammar Pro', icon: '✏️', earned: false),
    AchievementItem(label: 'AI Chatter', icon: '🤖', earned: true),
    AchievementItem(label: '50 Words', icon: '🏅', earned: true),
    AchievementItem(label: '100 Words', icon: '🥇', earned: false),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5);
    final secondaryColor = const Color(0xFFEEF0FF);
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    final firstName = widget.user['name']?.split(' ')[0] ?? 'Student';
    final email = widget.user['email'] ?? 'student@englishai.app';

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFEEF0FF),
                border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.12), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user['name'] ?? 'User',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    widget.user['level'] ?? 'Beginner',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Stats grid
                  Row(
                    children: [
                      _buildStatCard('Words', widget.user['learnedWords'] ?? '0', Icons.book, const Color(0xFF4F46E5)),
                      _buildStatCard(
                        'Favorites',
                        (() {
                          try {
                            final box = Hive.box('vocabulary_box');
                            final List<dynamic>? list = box.get('favorites_list');
                            return (list?.length ?? 0).toString();
                          } catch (_) {
                            return '0';
                          }
                        })(),
                        Icons.star,
                        const Color(0xFFF59E0B),
                      ),
                      _buildStatCard('Streak', '${widget.user['streak'] ?? '0'}d', Icons.trending_up, const Color(0xFF10B981)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress block
                  _buildCard(
                    title: 'Learning Progress',
                    child: Column(
                      children: [
                        _buildProgressBar('Vocabulary', 64, const Color(0xFF4F46E5)),
                        _buildProgressBar('Grammar', 42, const Color(0xFF0891B2)),
                        _buildProgressBar('Speaking', 28, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Achievements block
                  _buildCard(
                    title: 'Achievements',
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _achievements.length,
                      itemBuilder: (context, index) {
                        final a = _achievements[index];
                        return Opacity(
                          opacity: a.earned ? 1.0 : 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: a.earned ? const Color(0xFFEEF0FF) : const Color(0xFFECECF5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(a.icon, style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(
                                  a.label,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF0F0E2A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings block
                  _buildCard(
                    title: 'Settings',
                    child: Column(
                      children: [
                        _buildToggleSetting(
                          icon: Icons.notifications_none,
                          label: 'Push Notifications',
                          color: const Color(0xFF4F46E5),
                          bg: const Color(0xFFEEF0FF),
                          value: _notifications,
                          onChanged: (val) => setState(() => _notifications = val),
                        ),
                        _buildDivider(),
                        _buildToggleSetting(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          color: const Color(0xFF0891B2),
                          bg: const Color(0xFFECFEFF),
                          value: _darkMode,
                          onChanged: (val) => setState(() => _darkMode = val),
                        ),
                        _buildDivider(),
                        GestureDetector(
                          onTap: _showEditProfileDialog,
                          child: _buildLinkSetting(
                            icon: Icons.person_outline,
                            label: 'Edit Profile',
                            color: const Color(0xFF10B981),
                            bg: const Color(0xFFD1FAE5),
                          ),
                        ),
                        _buildDivider(),
                        _buildLinkSetting(
                          icon: Icons.language_outlined,
                          label: 'App Language',
                          color: const Color(0xFFF59E0B),
                          bg: const Color(0xFFFFFBEB),
                          trailingText: 'English',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: widget.onLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF1F2),
                        foregroundColor: const Color(0xFFD4183D),
                        shadowColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        side: BorderSide(color: const Color(0xFFD4183D).withOpacity(0.25)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: Text(
                        'Sign Out',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: cardBorderColor),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F0E2A),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF6B6B8A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF0F0E2A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF0F0E2A))),
              Text('$value%', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: const Color(0xFFECECF5),
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F0E2A)))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF4F46E5),
        ),
      ],
    );
  }

  Widget _buildLinkSetting({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    String? trailingText,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F0E2A)))),
        if (trailingText != null)
          Text(
            trailingText,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B6B8A)),
          ),
        const Icon(Icons.chevron_right, size: 20, color: Color(0xFF6B6B8A)),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(height: 12, color: const Color(0xFF4F46E5).withOpacity(0.12));
  }
}
