import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';

bool isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('vocabulary_box');
  try {
    await Firebase.initializeApp();
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
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

  void _onSplashDone() async {
    if (isFirebaseInitialized) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _loadFirestoreUserAndGo(currentUser.uid);
        return;
      }
    }

    setState(() {
      try {
        final box = Hive.box('vocabulary_box');
        final savedUser = box.get('user_profile');
        if (savedUser != null) {
          final Map<dynamic, dynamic> rawMap = savedUser as Map;
          _user = rawMap.map((key, value) => MapEntry(key.toString(), value.toString()));
          _screen = 'app';
          _currentTabIndex = 0;
          return;
        }
      } catch (_) {}
      _screen = 'auth';
    });
  }

  Future<void> _loadFirestoreUserAndGo(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _user = {
            'uid': uid,
            'name': data['name']?.toString() ?? '',
            'email': data['email']?.toString() ?? '',
            'level': data['level']?.toString() ?? 'Beginner',
            'streak': (data['streak'] ?? 0).toString(),
            'learnedWords': (data['learnedWords'] ?? 0).toString(),
          };
          // Cache locally in Hive
          try {
            Hive.box('vocabulary_box').put('user_profile', _user);
          } catch (_) {}
          _screen = 'app';
          _currentTabIndex = 0;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
    }
    setState(() {
      _screen = 'auth';
    });
  }

  void _onAuth(Map<String, String> user) {
    try {
      Hive.box('vocabulary_box').put('user_profile', user);
    } catch (_) {}
    setState(() {
      _user = user;
      _screen = 'app';
      _currentTabIndex = 0;
    });
  }

  void _onLogout() async {
    if (isFirebaseInitialized) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    try {
      final box = Hive.box('vocabulary_box');
      await box.delete('user_profile');
      await box.delete('favorites_list');
      await box.delete('favorites_data');
    } catch (_) {}
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
      VocabularyScreen(user: _user!, onNavigate: _navigateToTab),
      ChatScreen(user: _user!),
      NotificationsScreen(user: _user!, onNavigate: _navigateToTab),
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
