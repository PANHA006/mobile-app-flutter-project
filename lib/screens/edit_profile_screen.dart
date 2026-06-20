import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../main.dart'; // To access isFirebaseInitialized
import 'custom_snackbar.dart';
import '../utils/notification_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> user;
  final VoidCallback onUpdate;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.onUpdate,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPass = false;
  bool _showConfirmPass = false;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;
  Uint8List? _localImageBytes;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 500,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      // Update UI immediately with local bytes so user sees the picture instantly
      setState(() {
        _localImageBytes = bytes;
        if (!kIsWeb) {
          widget.user['photoUrl'] = image.path;
        }
      });
      widget.onUpdate();

      setState(() {
        _isUploadingPhoto = true;
      });

      final uid = widget.user['uid'];
      if (uid == null) {
        showCustomSnackBar(context, 'User ID not found.');
        return;
      }

      String? downloadUrl;

      // Upload to local backend server
      try {
        const String uploadUrl = 'https://english-ai-study-backend.onrender.com/api/upload';
        
        final base64Image = base64Encode(bytes);
        final response = await http.post(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'image': base64Image,
            'name': image.name,
          }),
        ).timeout(const Duration(seconds: 15));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['url'] != null) {
            downloadUrl = data['url'];
          }
        }
      } catch (uploadError) {
        debugPrint('Local backend upload failed: $uploadError');
      }

      // If local upload failed, fallback to local path
      if (downloadUrl == null) {
        downloadUrl = image.path;
        if (mounted) {
          showCustomSnackBar(
            context,
            'Saved locally. Could not upload image to local server.',
          );
        }
      } else {
        if (mounted) {
          showCustomSnackBar(context, 'Profile picture updated successfully!');
        }
      }

      setState(() {
        widget.user['photoUrl'] = downloadUrl!;
      });

      if (isFirebaseInitialized) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'photoUrl': downloadUrl,
        });
      }

      addAppNotification(
        title: 'Profile Picture Updated! 📸',
        body: 'Your profile picture has been updated successfully.',
        iconName: 'profile',
        uid: uid,
      );

      try {
        final box = Hive.box('vocabulary_box');
        box.put('user_profile', widget.user);
      } catch (e) { debugPrint('Error saving user profile to Hive after photo upload: $e'); }

      widget.onUpdate();
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'Error picking image: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showLevelSelectionDialog() {
    final uid = widget.user['uid'];
    String selectedLevel = widget.user['level'] ?? 'Beginner';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                          'Select English Level',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent, size: 24),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              await FirebaseFirestore.instance.collection('users').doc(uid).update({
                                'level': level,
                              });
                            } catch (e) { debugPrint('Error updating level in Firestore from edit profile: $e'); }
                          }
                          setState(() {});
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (context.mounted) Navigator.of(context).pop();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEEF0FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                level,
                                style: GoogleFonts.inter(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                                  fontSize: 15,
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 20)
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
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
          }
        );
      },
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      const Icon(Icons.check_circle, color: Color(0xFF4F46E5), size: 20),
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

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final uid = widget.user['uid'];

    if (name.isEmpty || email.isEmpty) {
      showCustomSnackBar(context, 'Name and Email cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Update memory
      widget.user['name'] = name;
      widget.user['email'] = email;

      // 2. Update Firebase Authentication Email & Firestore
      if (isFirebaseInitialized && uid != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          if (currentUser.email != email) {
            await currentUser.updateEmail(email);
          }
          // Update Firestore doc
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'name': name,
            'email': email,
          });
        }
      }

      // 3. Update Hive local storage
      try {
        final box = Hive.box('vocabulary_box');
        box.put('user_profile', widget.user);
      } catch (e) { debugPrint('Error saving user profile to Hive in edit profile: $e'); }

      // 4. Update Password if entered
      if (password.isNotEmpty) {
        if (password.length < 6) {
          throw 'Password must be at least 6 characters.';
        }
        if (password != confirmPassword) {
          throw 'Passwords do not match.';
        }
        if (isFirebaseInitialized) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await currentUser.updatePassword(password);
          }
        }
      }

      addAppNotification(
        title: 'Profile Updated! 👤',
        body: 'Your profile information has been updated successfully.',
        iconName: 'profile',
        uid: uid,
      );

      // Notify parent to refresh and pop
      widget.onUpdate();
      if (mounted) {
        showCustomSnackBar(context, 'Profile updated successfully!');
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? e.code;
      if (e.code == 'requires-recent-login') {
        msg = 'For security, changing password/email requires you to have logged in recently. Please sign out, log back in, and try again.';
      }
      if (mounted) {
        showCustomSnackBar(context, 'Firebase Auth Error: $msg');
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, 'Update failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5);
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    final firstName = widget.user['name']?.split(' ')[0] ?? 'Student';

    String? photoUrl = widget.user['photoUrl'];
    if (photoUrl != null) {
      if (photoUrl.contains('localhost:3000')) {
        photoUrl = photoUrl.replaceAll('http://localhost:3000', 'https://english-ai-study-backend.onrender.com');
      } else if (photoUrl.contains('10.0.2.2:3000')) {
        photoUrl = photoUrl.replaceAll('http://10.0.2.2:3000', 'https://english-ai-study-backend.onrender.com');
      }
      if (photoUrl.startsWith('http://english-ai-study-backend.onrender.com')) {
        photoUrl = photoUrl.replaceFirst('http://', 'https://');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Profile',
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
                onTap: _handleSave,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Header Banner with Confirm button
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Cover banner
                        Container(
                          height: 180,
                          width: double.infinity,
                          margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF4F46E5),
                                Color(0xFF3730A3),
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

                            ],
                          ),
                        ),
                        // Overlapping avatar with Camera icon
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
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEFF6FF),
                                    ),
                                    alignment: Alignment.center,
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: double.infinity,
                                        child: _isUploadingPhoto
                                            ? const Center(
                                                child: SizedBox(
                                                  width: 28,
                                                  height: 28,
                                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                                ),
                                              )
                                            : _localImageBytes != null
                                                ? Image.memory(
                                                    _localImageBytes!,
                                                    fit: BoxFit.cover,
                                                  )
                                                : (photoUrl != null && photoUrl.isNotEmpty)
                                                    ? (kIsWeb || photoUrl.startsWith('http') || photoUrl.startsWith('https') || photoUrl.startsWith('blob:')
                                                        ? Image.network(
                                                            photoUrl,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Center(
                                                                child: Text(
                                                                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                                                  style: GoogleFonts.outfit(
                                                                    color: primaryColor,
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
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Center(
                                                                child: Text(
                                                                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                                                  style: GoogleFonts.outfit(
                                                                    color: primaryColor,
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
                                                            color: primaryColor,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 34,
                                                          ),
                                                        ),
                                                      ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 54),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          // 1. Edit Information card
                          _buildSectionCard(
                            title: 'Edit Information',
                            child: Column(
                              children: [
                                _buildInputField(
                                  label: 'Name',
                                  icon: Icons.person_outline,
                                  controller: _nameController,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Email',
                                  icon: Icons.mail_outline,
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Set up card
                          _buildSectionCard(
                            title: 'Set up',
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _showLevelSelectionDialog,
                                  child: _buildLinkRow(
                                    icon: Icons.school_outlined,
                                    label: 'English Level',
                                    color: const Color(0xFF10B981),
                                    bg: const Color(0xFFD1FAE5),
                                    valueText: widget.user['level'] ?? 'Beginner',
                                  ),
                                ),
                                Divider(height: 24, color: primaryColor.withOpacity(0.12)),
                                GestureDetector(
                                  onTap: _showLanguageSelectionDialog,
                                  child: _buildLinkRow(
                                    icon: Icons.language_outlined,
                                    label: 'App Language',
                                    color: const Color(0xFFF59E0B),
                                    bg: const Color(0xFFFFFBEB),
                                    valueText: 'English',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Edit Password card
                          _buildSectionCard(
                            title: 'Edit Password',
                            child: Column(
                              children: [
                                _buildInputField(
                                  label: 'New Password',
                                  icon: Icons.lock_outline,
                                  controller: _passwordController,
                                  obscureText: !_showPass,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B6B8A),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showPass = !_showPass;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  label: 'Confirm New Password',
                                  icon: Icons.lock_outline,
                                  controller: _confirmPasswordController,
                                  obscureText: !_showConfirmPass,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _showConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF6B6B8A),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _showConfirmPass = !_showConfirmPass;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: const Color(0xFF0F0E2A),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final inputBgColor = const Color(0xFFF0F1FA);
    final mutedColor = const Color(0xFF6B6B8A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6B8A),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF0F0E2A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputBgColor,
            prefixIcon: Icon(icon, color: mutedColor, size: 20),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkRow({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required String valueText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F0E2A),
              ),
            ),
          ),
          Text(
            valueText,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B6B8A),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF6B6B8A)),
        ],
      ),
    );
  }
}
