import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../main.dart'; // To access isFirebaseInitialized
import 'edit_profile_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  Map<String, dynamic> _getCategoryLevelAndProgress(String key) {
    final refreshes = int.tryParse(widget.user[key] ?? '0') ?? 0;
    if (refreshes < 1) {
      return {
        'level': 0,
        'percent': 0,
      };
    }

    int level = 1;
    int currentLevelRequirement = 1;

    while (currentLevelRequirement * 2 <= refreshes) {
      currentLevelRequirement *= 2;
      level++;
    }

    int nextLevelRequirement = currentLevelRequirement * 2;
    double progress = (refreshes - currentLevelRequirement) /
        (nextLevelRequirement - currentLevelRequirement);
    int percent = (progress * 100).toInt();

    return {
      'level': level,
      'percent': percent,
    };
  }

  void _showEditProfileDialog() {
    final uid = widget.user['uid'];
    if (uid == null) return;

    final nameController = TextEditingController(text: widget.user['name']);
    String selectedLevel = widget.user['level'] ?? 'Beginner';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Edit Profile',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
                    DropdownMenuItem(
                        value: 'Beginner', child: Text('Beginner')),
                    DropdownMenuItem(
                        value: 'Intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(
                        value: 'Advanced', child: Text('Advanced')),
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
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: Colors.grey)),
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
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                          'name': newName,
                          'level': selectedLevel,
                        });
                      } catch (_) {}
                    }
                    setState(() {});
                    Navigator.of(context).pop();
                  }
                },
                child: Text('Save',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showLevelSelectionDialog() {
    final uid = widget.user['uid'];
    String selectedLevel = widget.user['level'] ?? 'Beginner';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and red close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select English Level',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.redAccent, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Option cards
                  ...['Beginner', 'Intermediate', 'Advanced'].map((level) {
                    final isSelected = selectedLevel == level;
                    return GestureDetector(
                      onTap: () async {
                        setDialogState(() {
                          selectedLevel = level;
                        });
                        widget.user['level'] = level;
                        if (isFirebaseInitialized && uid != null) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                              'level': level,
                            });
                          } catch (_) {}
                        }
                        setState(() {});
                        Future.delayed(const Duration(milliseconds: 200), () {
                          if (context.mounted) Navigator.of(context).pop();
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEEF0FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFE2E8F0),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              level,
                              style: GoogleFonts.inter(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : const Color(0xFF0F172A),
                                fontSize: 15,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF4F46E5), size: 20)
                            else
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      width: 1.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select App Language',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.redAccent, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4F46E5),
                      width: 2.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'English',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4F46E5),
                          fontSize: 15,
                        ),
                      ),
                      const Icon(Icons.check_circle,
                          color: Color(0xFF4F46E5), size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
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

    String? photoUrl = widget.user['photoUrl'];
    if (photoUrl != null) {
      if (photoUrl.contains('localhost:3000')) {
        photoUrl = photoUrl.replaceAll('http://localhost:3000', 'https://english-ai-study-backend.onrender.com');
      } else if (photoUrl.contains('10.0.2.2:3000')) {
        photoUrl = photoUrl.replaceAll('http://10.0.2.2:3000', 'https://english-ai-study-backend.onrender.com');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(
                        user: widget.user,
                        onUpdate: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4F46E5),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Custom Header Banner matching Mockup
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Teal-Cyan gradient background banner
                  Container(
                    height: 180,
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                        left: 16, right: 16, top: 16, bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1), // Lighter Indigo
                          Color(0xFF4F46E5), // Indigo (Primary Color)
                          Color(0xFF3730A3), // Darker Indigo
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Soft bokeh circles
                        Positioned(
                          left: -20,
                          top: 20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: -30,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Overlapping avatar
                  Positioned(
                    bottom: -36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEFF6FF),
                            ),
                            child: ClipOval(
                              child: (photoUrl != null &&
                                      photoUrl.isNotEmpty &&
                                      !photoUrl.startsWith('blob:'))
                                  ? (kIsWeb ||
                                          photoUrl.startsWith('http') ||
                                          photoUrl.startsWith('https')
                                      ? Image.network(
                                          photoUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFF4F46E5),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 34,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(photoUrl),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFF4F46E5),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 34,
                                                ),
                                              ),
                                            );
                                          },
                                        ))
                                  : Center(
                                      child: Text(
                                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF4F46E5),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 34,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        // Online status indicator green dot
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Name & Level Text Details
              Text(
                widget.user['name'] ?? 'User',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0F172A),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                email,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // Social Badges Row matching Mockup
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialIcon(
                    color: const Color(0xFFEA4C89),
                    bg: const Color(0xFFFFF1F2),
                    icon: Icons.sports_basketball_outlined,
                  ),
                  _buildSocialIconText(
                    color: const Color(0xFF0057FF),
                    bg: const Color(0xFFEFF6FF),
                    text: 'Bē',
                  ),
                  _buildSocialIcon(
                    color: const Color(0xFFE1306C),
                    bg: const Color(0xFFFFF1F2),
                    icon: Icons.camera_alt_outlined,
                  ),
                  _buildSocialIconText(
                    color: const Color(0xFF0A66C2),
                    bg: const Color(0xFFF0F9FF),
                    text: 'in',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Stats grid
                    Row(
                      children: [
                        _buildStatCard(
                          'Refresh',
                          widget.user['refreshCount'] ?? '0',
                          Icons.refresh_rounded,
                          const Color(0xFF10B981),
                        ),
                        _buildStatCard(
                          'Favorites',
                          (() {
                            try {
                              final box = Hive.box('vocabulary_box');
                              final List<dynamic>? list =
                                  box.get('favorites_list');
                              return (list?.length ?? 0).toString();
                            } catch (_) {
                              return '0';
                            }
                          })(),
                          Icons.favorite_rounded,
                          const Color(0xFFEF4444),
                        ),
                        _buildStatCard(
                          'Achieve',
                          (() {
                            final wordsLevel = _getCategoryLevelAndProgress('refresh_Words')['level'] as int;
                            final nounsLevel = _getCategoryLevelAndProgress('refresh_nouns')['level'] as int;
                            final pronounsLevel = _getCategoryLevelAndProgress('refresh_pronouns')['level'] as int;
                            final verbsLevel = _getCategoryLevelAndProgress('refresh_verbs')['level'] as int;
                            final adjectiveLevel = _getCategoryLevelAndProgress('refresh_adjective')['level'] as int;
                            return (wordsLevel + nounsLevel + pronounsLevel + verbsLevel + adjectiveLevel).toString();
                          })(),
                          Icons.emoji_events,
                          const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress block
                    _buildCard(
                      title: 'Learning Progress',
                      child: Column(
                        children: [
                          (() {
                            final stats =
                                _getCategoryLevelAndProgress('refresh_Words');
                            return _buildProgressBar(
                                'Words Vocabulary (Level ${stats['level']})',
                                stats['percent'],
                                const Color(0xFF4F46E5));
                          })(),
                          (() {
                            final stats =
                                _getCategoryLevelAndProgress('refresh_nouns');
                            return _buildProgressBar(
                                'Nouns (Level ${stats['level']})',
                                stats['percent'],
                                const Color(0xFF0891B2));
                          })(),
                          (() {
                            final stats = _getCategoryLevelAndProgress(
                                'refresh_pronouns');
                            return _buildProgressBar(
                                'Pronouns (Level ${stats['level']})',
                                stats['percent'],
                                const Color(0xFF10B981));
                          })(),
                          (() {
                            final stats =
                                _getCategoryLevelAndProgress('refresh_verbs');
                            return _buildProgressBar(
                                'Verbs (Level ${stats['level']})',
                                stats['percent'],
                                const Color(0xFFF59E0B));
                          })(),
                          (() {
                            final stats = _getCategoryLevelAndProgress(
                                'refresh_adjective');
                            return _buildProgressBar(
                                'Adjective (Level ${stats['level']})',
                                stats['percent'],
                                const Color(0xFFEC4899));
                          })(),
                        ],
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
                            onChanged: (val) =>
                                setState(() => _notifications = val),
                          ),
                          _buildDivider(),
                          _buildToggleSetting(
                            icon: Icons.dark_mode_outlined,
                            label: 'Dark Mode',
                            color: const Color(0xFF0891B2),
                            bg: const Color(0xFFECFEFF),
                            value: _darkMode,
                            onChanged: null,
                          ),
                          _buildDivider(),
                          GestureDetector(
                            onTap: _showLevelSelectionDialog,
                            child: _buildLinkSetting(
                              icon: Icons.school_outlined,
                              label: 'English Level',
                              color: const Color(0xFF10B981),
                              bg: const Color(0xFFD1FAE5),
                              trailingText: widget.user['level'] ?? 'Beginner',
                            ),
                          ),
                          _buildDivider(),
                          GestureDetector(
                            onTap: _showLanguageSelectionDialog,
                            child: _buildLinkSetting(
                              icon: Icons.language_outlined,
                              label: 'App Language',
                              color: const Color(0xFFF59E0B),
                              bg: const Color(0xFFFFFBEB),
                              trailingText: 'English',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Logout button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: widget.onLogout,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDC2626), // Red 600
                          side: const BorderSide(
                              color: Color(0xFFDC2626), width: 1.8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.logout,
                            size: 18, color: Color(0xFFDC2626)),
                        label: Text(
                          'Sign Out',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.08);
    final glowColor = color.withOpacity(0.1);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: glowColor,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
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
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF0F0E2A))),
              Text('$value%',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 13, color: color)),
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
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF0F0E2A)))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4F46E5),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkSetting({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    String? trailingText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 14, color: const Color(0xFF0F0E2A)))),
          if (trailingText != null)
            Text(
              trailingText,
              style: GoogleFonts.inter(
                  fontSize: 12, color: const Color(0xFF6B6B8A)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF6B6B8A)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 12, color: const Color(0xFF4F46E5).withOpacity(0.12));
  }

  Widget _buildSocialIcon(
      {required Color color, required Color bg, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.35), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildSocialIconText(
      {required Color color, required Color bg, required String text}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.35), width: 2.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
