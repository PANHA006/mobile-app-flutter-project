import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../utils/notification_helper.dart';
import '../main.dart'; // To access isFirebaseInitialized

class AuthScreen extends StatefulWidget {
  final Function(Map<String, String>) onAuth;
  const AuthScreen({super.key, required this.onAuth});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  String _mode = 'login'; // 'login' or 'register'
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _showPass = false;
  bool _showConfirmPass = false;
  bool _isLoading = false;
  String _error = '';

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();

    // Validation logic
    if (_mode == 'register') {
      if (name.isEmpty) {
        setState(() {
          _error = 'Please enter your Full Name.';
        });
        return;
      }
      if (name.length < 2) {
        setState(() {
          _error = 'Name must be at least 2 characters long.';
        });
        return;
      }
    }

    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter your email address.';
      });
      return;
    }

    // Email regex validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _error = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _error = 'Please enter your password.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters long.';
      });
      return;
    }

    if (_mode == 'register') {
      if (confirmPassword.isEmpty) {
        setState(() {
          _error = 'Please confirm your password.';
        });
        return;
      }
      if (password != confirmPassword) {
        setState(() {
          _error = 'Passwords do not match.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      if (isFirebaseInitialized) {
        if (_mode == 'register') {
          // Register Firebase User
          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final uid = credential.user!.uid;

          // Create Firestore User Document
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'name': name,
            'email': email,
            'level': 'Beginner',
            'streak': 0,
            'learnedWords': 0,
            'favoriteWords': [],
            'photoUrl': '',
            'refreshCount': 0,
            'refresh_Words': 0,
            'refresh_nouns': 0,
            'refresh_pronouns': 0,
            'refresh_verbs': 0,
            'refresh_adjective': 0,
            'daysUsedCount': 0,
            'activeDays': [],
            'createdAt': FieldValue.serverTimestamp(),
          });

          try {
            Hive.box('vocabulary_box').delete('notifications_list');
          } catch (e) { debugPrint('Error clearing notifications on register: $e'); }

          addAppNotification(
            title: 'Welcome to English AI Study App! 👋',
            body: 'Start your learning journey now. Learn vocabulary, practice grammar, and chat with your personal AI English tutor!',
            iconName: 'welcome',
            uid: uid,
          );

          widget.onAuth({
            'uid': uid,
            'name': name,
            'email': email,
            'level': 'Beginner',
            'streak': '0',
            'learnedWords': '0',
            'photoUrl': '',
            'refreshCount': '0',
            'refresh_Words': '0',
            'refresh_nouns': '0',
            'refresh_pronouns': '0',
            'refresh_verbs': '0',
            'refresh_adjective': '0',
            'daysUsedCount': '0',
            'activeDays': '[]',
          });
        } else {
          // Login Firebase User
          final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          final uid = credential.user!.uid;

          // Fetch Firestore User Profile
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final displayName = data['name']?.toString() ?? 'Student';
            final notifs = data['notifications_list'];
            if (notifs != null) {
              try {
                Hive.box('vocabulary_box').put('notifications_list', notifs);
              } catch (e) { debugPrint('Error saving notifications to Hive on login: $e'); }
            } else {
              try {
                Hive.box('vocabulary_box').delete('notifications_list');
              } catch (e) { debugPrint('Error clearing notifications on login (no data): $e'); }
            }

            addAppNotification(
              title: 'Welcome back, $displayName! 🎉',
              body: 'Glad to see you again! Ready to practice some new English words today?',
              iconName: 'welcome',
              uid: uid,
            );

            widget.onAuth({
              'uid': uid,
              'name': data['name']?.toString() ?? '',
              'email': data['email']?.toString() ?? '',
              'level': data['level']?.toString() ?? 'Beginner',
              'streak': (data['streak'] ?? 0).toString(),
              'learnedWords': (data['learnedWords'] ?? 0).toString(),
              'photoUrl': data['photoUrl']?.toString() ?? '',
              'refreshCount': (data['refreshCount'] ?? 0).toString(),
              'refresh_Words': (data['refresh_Words'] ?? 0).toString(),
              'refresh_nouns': (data['refresh_nouns'] ?? 0).toString(),
              'refresh_pronouns': (data['refresh_pronouns'] ?? 0).toString(),
              'refresh_verbs': (data['refresh_verbs'] ?? 0).toString(),
              'refresh_adjective': (data['refresh_adjective'] ?? 0).toString(),
              'daysUsedCount': (data['daysUsedCount'] ?? 0).toString(),
              'activeDays': data['activeDays'] != null ? json.encode(data['activeDays']) : '[]',
            });
          } else {
            // Document doesn't exist, create it as a recovery step
            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'uid': uid,
              'name': email.split('@')[0],
              'email': email,
              'level': 'Beginner',
              'streak': 0,
              'learnedWords': 0,
              'favoriteWords': [],
              'photoUrl': '',
              'refreshCount': 0,
              'refresh_Words': 0,
              'refresh_nouns': 0,
              'refresh_pronouns': 0,
              'refresh_verbs': 0,
              'refresh_adjective': 0,
              'daysUsedCount': 0,
              'activeDays': [],
              'createdAt': FieldValue.serverTimestamp(),
            });
            widget.onAuth({
              'uid': uid,
              'name': email.split('@')[0],
              'email': email,
              'level': 'Beginner',
              'streak': '0',
              'learnedWords': '0',
              'photoUrl': '',
              'refreshCount': '0',
              'refresh_Words': '0',
              'refresh_nouns': '0',
              'refresh_pronouns': '0',
              'refresh_verbs': '0',
              'refresh_adjective': '0',
              'daysUsedCount': '0',
              'activeDays': '[]',
            });
          }
        }
      } else {
        // Fallback to local Hive if Firebase is not initialized
        final displayName = _mode == 'register' ? name : (email.split('@')[0]);
        try {
          Hive.box('vocabulary_box').delete('notifications_list');
        } catch (e) { debugPrint('Error clearing notifications in fallback mode: $e'); }

        addAppNotification(
          title: _mode == 'register' ? 'Welcome to English AI Study App! 👋' : 'Welcome back, $displayName! 🎉',
          body: _mode == 'register' 
              ? 'Start your learning journey now. Learn vocabulary, practice grammar, and chat with your personal AI English tutor!'
              : 'Glad to see you again! Ready to practice some new English words today?',
          iconName: 'welcome',
        );

        widget.onAuth({
          'name': displayName,
          'email': email,
          'photoUrl': '',
          'refreshCount': '0',
          'refresh_Words': '0',
          'refresh_nouns': '0',
          'refresh_pronouns': '0',
          'refresh_verbs': '0',
          'refresh_adjective': '0',
          'daysUsedCount': '0',
          'activeDays': '[]',
        });
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Authentication failed.';
      if (e.code == 'operation-not-allowed') {
        msg = 'Email/Password Sign-In/Register is not enabled in the Firebase Console.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'The email address is already in use by another account.';
      } else if (e.code == 'weak-password') {
        msg = 'The password is too weak.';
      } else if (e.code == 'invalid-email') {
        msg = 'The email address is badly formatted.';
      } else if (e.code == 'user-not-found') {
        msg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        msg = 'Incorrect password.';
      } else {
        msg = e.message ?? 'Firebase Auth Error (${e.code})';
      }
      setState(() {
        _error = msg;
      });
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('API key') || errorMsg.contains('requests from this referrer') || errorMsg.contains('operation')) {
        setState(() {
          _error = 'Firebase Auth setup required: please enable Email/Password provider in the Firebase Console.';
        });
      } else if (errorMsg.contains('permission-denied') || errorMsg.contains('PERMISSION_DENIED')) {
        setState(() {
          _error = 'Database access denied: Please ensure Cloud Firestore is enabled and security rules are configured to allow writes.';
        });
      } else if (errorMsg.contains('network') || errorMsg.contains('Network') || errorMsg.contains('SocketException') || errorMsg.contains('connection')) {
        setState(() {
          _error = 'Connection error: Please check your internet connection and verify Firebase Console setups.';
        });
      } else {
        setState(() {
          _error = 'An error occurred: $e\n(Tip: Ensure Firebase Auth & Cloud Firestore are enabled in your project console)';
        });
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5);
    final secondaryColor = const Color(0xFFEEF0FF);
    final inputBgColor = const Color(0xFFF0F1FA);
    final mutedColor = const Color(0xFF6B6B8A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wave header
            Container(
              width: double.infinity,
              color: primaryColor,
              padding: const EdgeInsets.only(top: 60, bottom: 25, left: 24, right: 24),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.school,
                        size: 84,
                        color: Colors.white,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 26,
                          color: Colors.amber[300],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _mode == 'login' ? 'Welcome back!' : 'Create account',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _mode == 'login'
                        ? 'Sign in to continue learning'
                        : 'Start your English journey',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (!isFirebaseInitialized) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Firebase not initialized. Running in offline/local fallback mode.',
                              style: GoogleFonts.inter(
                                color: Colors.amber.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Tab toggle
                  Container(
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _mode = 'login';
                                _error = '';
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _mode == 'login' ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.outfit(
                                  color: _mode == 'login' ? Colors.white : mutedColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _mode = 'register';
                                _error = '';
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _mode == 'register' ? primaryColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                'Register',
                                style: GoogleFonts.outfit(
                                  color: _mode == 'register' ? Colors.white : mutedColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fields
                  if (_mode == 'register') ...[
                    _buildField(
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      controller: _nameController,
                      placeholder: 'John Smith',
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildField(
                    label: 'Email',
                    icon: Icons.mail_outline,
                    controller: _emailController,
                    placeholder: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  _buildField(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    placeholder: '••••••••',
                    obscureText: !_showPass,
                    suffix: IconButton(
                      icon: Icon(
                        _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: mutedColor,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showPass = !_showPass;
                        });
                      },
                    ),
                  ),
                  if (_mode == 'login') ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: GoogleFonts.inter(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_mode == 'register') ...[
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      controller: _confirmPasswordController,
                      placeholder: '••••••••',
                      obscureText: !_showConfirmPass,
                      suffix: IconButton(
                        icon: Icon(
                          _showConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: mutedColor,
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

                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFD4183D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.4),
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            _mode == 'login' ? 'Sign In' : 'Create Account',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: const Color(0xFF4F46E5).withOpacity(0.12))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'or continue with',
                          style: GoogleFonts.inter(
                            color: mutedColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                          child: Divider(color: const Color(0xFF4F46E5).withOpacity(0.12))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google button
                  OutlinedButton(
                    onPressed: () {}, // Inactive
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFF4F46E5).withOpacity(0.08),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'G',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  color: const Color.fromARGB(255, 224, 55, 55),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F0E2A).withOpacity(0.38),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String placeholder,
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
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0F0E2A),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: inputBgColor,
            borderRadius: BorderRadius.circular(100),
          ),
          padding: EdgeInsets.only(left: 16, right: suffix != null ? 4 : 16),
          child: Row(
            children: [
              Icon(icon, color: mutedColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.inter(
                      color: mutedColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF0F0E2A),
                  ),
                ),
              ),
              if (suffix != null) suffix,
            ],
          ),
        ),
      ],
    );
  }
}
