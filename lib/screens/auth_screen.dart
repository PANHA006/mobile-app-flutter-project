import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _nameController = TextEditingController();
  bool _showPass = false;
  String _error = '';

  void _handleSubmit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (_mode == 'register' && name.isEmpty)) {
      setState(() {
        _error = 'Please fill in all fields.';
      });
      return;
    }

    setState(() {
      _error = '';
    });

    widget.onAuth({
      'name': _mode == 'register' ? name : (email.split('@')[0]),
      'email': email,
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  // Tab toggle
                  Container(
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.circular(16),
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
                                borderRadius: BorderRadius.circular(12),
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
                                borderRadius: BorderRadius.circular(12),
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
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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

                  if (_mode == 'login') ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.inter(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
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
                    onPressed: () {
                      widget.onAuth({
                        'name': 'Demo Student',
                        'email': 'demo@englishai.app',
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFF4F46E5).withOpacity(0.12),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0F0E2A),
                            fontWeight: FontWeight.w500,
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
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
