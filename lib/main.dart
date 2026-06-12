import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English AI Study App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
          background: const Color(0xFFF7F8FF),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const MainScreenController(),
    );
  }
}

class MainScreenController extends StatefulWidget {
  const MainScreenController({super.key});

  @override
  State<MainScreenController> createState() => _MainScreenControllerState();
}

class _MainScreenControllerState extends State<MainScreenController> {
  String _screen = 'splash'; // 'splash', 'auth', 'app'
  int _currentTabIndex = 0; // 0: Home, 1: Vocabulary, 2: Chat, 3: Notifications, 4: Profile
  Map<String, String>? _user;

  void _onSplashDone() {
    setState(() {
      _screen = 'auth';
    });
  }

  void _onAuth(Map<String, String> user) {
    setState(() {
      _user = user;
      _screen = 'app';
      _currentTabIndex = 0;
    });
  }

  void _onLogout() {
    setState(() {
      _user = null;
      _screen = 'auth';
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screen == 'splash') {
      return SplashScreen(onDone: _onSplashDone);
    }

    if (_screen == 'auth') {
      return AuthScreen(onAuth: _onAuth);
    }

    // Main App with Tabs
    final screens = [
      HomeScreen(user: _user!, onNavigate: _navigateToTab),
      const VocabularyScreen(),
      const ChatScreen(),
      const NotificationsScreen(),
      ProfileScreen(user: _user!, onLogout: _onLogout),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFF4F46E5).withOpacity(0.12),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _navigateToTab,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: const Color(0xFF6B6B8A),
          selectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w400,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Words',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('2'),
                child: Icon(Icons.notifications_outlined),
              ),
              activeIcon: Badge(
                label: Text('2'),
                child: Icon(Icons.notifications),
              ),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
