import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/vocabulary_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/notification_helper.dart';

bool isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('vocabulary_box');
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBEBl9fUKI_DKzJ-S84qKJDoRIZERC2py4',
          authDomain: 'gen-lang-client-0730467006.firebaseapp.com',
          appId: '1:897475282164:web:03eb646ade2001f4d50aa1',
          messagingSenderId: '897475282164',
          projectId: 'gen-lang-client-0730467006',
          storageBucket: 'gen-lang-client-0730467006.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
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
  Future<void>? _initSessionFuture;
  String _targetScreen = 'auth';
  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    _initSessionFuture = _checkSessionInBackground();
    _startUsageTracking();
  }

  @override
  void dispose() {
    _usageTimer?.cancel();
    super.dispose();
  }

  void _startUsageTracking() {
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_user != null && _screen == 'app') {
        _incrementMinutesToday();
      }
    });
  }

  void _incrementMinutesToday() {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final currentMins = int.tryParse(_user!['minsToday'] ?? '0') ?? 0;
      final newMins = _user!['lastActiveDate'] != todayStr ? 1 : currentMins + 1;
      
      setState(() {
        if (_user!['lastActiveDate'] != todayStr) {
          _user!['lastActiveDate'] = todayStr;
          _user!['minsToday'] = '1';
        } else {
          _user!['minsToday'] = newMins.toString();
        }
      });
      
      final box = Hive.box('vocabulary_box');
      box.put('user_profile', _user);
      
      final uid = _user!['uid'];
      if (uid != null && isFirebaseInitialized) {
        FirebaseFirestore.instance.collection('users').doc(uid).update({
          'minsToday': int.parse(_user!['minsToday']!),
          'lastActiveDate': todayStr,
        }).catchError((e) { debugPrint('Error updating minsToday in Firestore: $e'); });
      }

      // Trigger notification if goal (30 mins) is met
      if (currentMins < 30 && newMins >= 30) {
        addAppNotification(
          title: 'Daily Study Goal Achieved! ⚡',
          body: 'Congratulations! You have completed your 30 minutes daily study goal!',
          iconName: 'goal',
          uid: uid,
        );
      }
    } catch (e) { debugPrint('Error incrementing minutes today: $e'); }
  }

  Future<void> _checkSessionInBackground() async {
    if (isFirebaseInitialized) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            _user = {
              'uid': currentUser.uid,
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
              'minsToday': (data['minsToday'] ?? 0).toString(),
              'lastActiveDate': data['lastActiveDate']?.toString() ?? '',
            };
            _recordActiveDay(_user!);
            final notifs = data['notifications_list'];
            if (notifs != null) {
              try {
                Hive.box('vocabulary_box').put('notifications_list', notifs);
              } catch (e) { debugPrint('Error saving notifications to Hive: $e'); }
            }
            try {
              Hive.box('vocabulary_box').put('user_profile', _user);
            } catch (e) { debugPrint('Error saving user profile to Hive: $e'); }
            await _syncFavoritesFromFirestore(currentUser.uid);
            _targetScreen = 'app';
            return;
          }
        }
      } catch (e) {
        debugPrint('Error during background session check: $e');
      }
      _targetScreen = 'auth';
    } else {
      try {
        final box = Hive.box('vocabulary_box');
        final savedUser = box.get('user_profile');
        if (savedUser != null) {
          final Map<dynamic, dynamic> rawMap = savedUser as Map;
          _user = rawMap.map((key, value) => MapEntry(key.toString(), value.toString()));
          _user!['minsToday'] = _user!['minsToday'] ?? '0';
          _user!['lastActiveDate'] = _user!['lastActiveDate'] ?? '';
          _recordActiveDay(_user!);
          _targetScreen = 'app';
          return;
        }
      } catch (e) { debugPrint('Error loading saved user from Hive: $e'); }
      _targetScreen = 'auth';
    }
  }

  Future<void> _syncFavoritesFromFirestore(String uid) async {
    if (!isFirebaseInitialized) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('uid', isEqualTo: uid)
          .get();
      final docs = snapshot.docs;
      docs.sort((a, b) {
        final aTime = a.data()['createdAt'] as Timestamp?;
        final bTime = b.data()['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      final List<String> favoritesList = [];
      final List<Map<String, dynamic>> favoritesData = [];

      for (var doc in docs) {
        final data = doc.data();
        final wordId = data['wordId']?.toString() ?? '';
        if (wordId.isNotEmpty) {
          favoritesList.add(wordId);
          favoritesData.add({
            'word_en': data['word_en'] ?? data['wordId'] ?? '',
            'word_kh': data['word_kh'] ?? '',
            'example': data['example'] ?? '',
            'level': data['level'] ?? 'FAVORITE',
            'phonetic': data['phonetic'] ?? '',
            'audio_url': data['audio_url'] ?? '',
          });
        }
      }

      final box = Hive.box('vocabulary_box');
      await box.put('favorites_list', favoritesList);
      await box.put('favorites_data', json.encode(favoritesData));
    } catch (e) {
      debugPrint('Error syncing favorites: $e');
    }
  }

  void _recordActiveDay(Map<String, String> user) {
    try {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final activeDaysRaw = user['activeDays'] ?? '[]';
      List<dynamic> activeDaysList = [];
      try {
        activeDaysList = json.decode(activeDaysRaw);
      } catch (e) { debugPrint('Error decoding activeDays JSON: $e'); }
      
      if (!activeDaysList.contains(todayStr)) {
        activeDaysList.add(todayStr);
        user['activeDays'] = json.encode(activeDaysList);
        user['daysUsedCount'] = activeDaysList.length.toString();
        
        try {
          final box = Hive.box('vocabulary_box');
          box.put('user_profile', user);
        } catch (e) { debugPrint('Error saving user profile to Hive in _recordActiveDay: $e'); }
        
        final uid = user['uid'];
        final newDaysCount = activeDaysList.length;
        final milestones = [1, 2, 3, 4, 5, 6, 7, 10, 20, 40, 80, 100];
        if (milestones.contains(newDaysCount)) {
          addAppNotification(
            title: 'Active Learning Milestone! 🏆',
            body: 'Congratulations! You have completed $newDaysCount days of active learning on the app!',
            iconName: 'congrats',
            uid: uid,
          );
        }

        if (uid != null && isFirebaseInitialized) {
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'activeDays': activeDaysList,
            'daysUsedCount': activeDaysList.length,
          }).catchError((e) { debugPrint('Error updating activeDays in Firestore: $e'); });
        }
      }
    } catch (e) { debugPrint('Error recording active day: $e'); }
  }

  void _onSplashDone() async {
    if (_initSessionFuture != null) {
      await _initSessionFuture;
    }
    setState(() {
      _screen = _targetScreen;
      _currentTabIndex = 0;
    });
  }

  void _onAuth(Map<String, String> user) {
    user['minsToday'] = user['minsToday'] ?? '0';
    user['lastActiveDate'] = user['lastActiveDate'] ?? '';
    _recordActiveDay(user);
    try {
      Hive.box('vocabulary_box').put('user_profile', user);
    } catch (e) { debugPrint('Error saving user profile to Hive in _onAuth: $e'); }
    final uid = user['uid'];
    if (uid != null) {
      _syncFavoritesFromFirestore(uid);
    }
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
      } catch (e) { debugPrint('Error signing out from Firebase: $e'); }
    }
    try {
      final box = Hive.box('vocabulary_box');
      await box.delete('user_profile');
      await box.delete('favorites_list');
      await box.delete('favorites_data');
      await box.delete('notifications_list');
    } catch (e) { debugPrint('Error clearing Hive data on logout: $e'); }
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
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Words',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'AI Chat',
            ),
            BottomNavigationBarItem(
              icon: ValueListenableBuilder(
                valueListenable: Hive.box('vocabulary_box').listenable(keys: ['notifications_list']),
                builder: (context, Box box, _) {
                  final List<dynamic> list = box.get('notifications_list') ?? [];
                  final unreadCount = list.where((n) => n['unread'] == true).length;
                  if (unreadCount > 0) {
                    return Badge(
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.notifications_outlined),
                    );
                  }
                  return const Icon(Icons.notifications_outlined);
                },
              ),
              activeIcon: ValueListenableBuilder(
                valueListenable: Hive.box('vocabulary_box').listenable(keys: ['notifications_list']),
                builder: (context, Box box, _) {
                  final List<dynamic> list = box.get('notifications_list') ?? [];
                  final unreadCount = list.where((n) => n['unread'] == true).length;
                  if (unreadCount > 0) {
                    return Badge(
                      label: Text(unreadCount.toString()),
                      child: const Icon(Icons.notifications),
                    );
                  }
                  return const Icon(Icons.notifications);
                },
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
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
