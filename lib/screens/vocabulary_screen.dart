import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // To access isFirebaseInitialized
import 'custom_snackbar.dart';
import '../utils/notification_helper.dart';

class WordItem {
  final String word;
  final String meaningKh;
  final String example;
  final String level;
  final String phonetic;
  final String audioUrl;

  const WordItem({
    required this.word,
    required this.meaningKh,
    required this.example,
    required this.level,
    required this.phonetic,
    required this.audioUrl,
  });

  factory WordItem.fromJson(Map<String, dynamic> json, String selectedLevel) {
    return WordItem(
      word: json['word_en'] ?? json['word'] ?? '',
      meaningKh: json['word_kh'] ?? json['meaning_kh'] ?? '',
      example: json['example'] ?? '',
      level: selectedLevel.toUpperCase(),
      phonetic: json['phonetic'] ?? '',
      audioUrl: json['audio_url'] ?? json['audio'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word_en': word,
      'word_kh': meaningKh,
      'example': example,
      'level': level,
      'phonetic': phonetic,
      'audio_url': audioUrl,
    };
  }
}

class NumberGroup {
  final String title;
  final String meaningKh;
  final int startIndex;
  final int endIndex;

  const NumberGroup({
    required this.title,
    required this.meaningKh,
    required this.startIndex,
    required this.endIndex,
  });
}

class VocabularyScreen extends StatefulWidget {
  final Map<String, String> user;
  final Function(int) onNavigate;
  final VoidCallback? onOpenDrawer;

  const VocabularyScreen({
    super.key,
    required this.user,
    required this.onNavigate,
    this.onOpenDrawer,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  // Selected level: derived from user profile
  late String _selectedLevel;
  List<WordItem> _loadedWords = [];
  bool _isLoading = false;

  // Favorites & Learned Set (stored in Hive + Firestore)
  final Set<String> _favorites = {};
  final Set<String> _learnedWords = {};
  List<WordItem> _favoriteWords = [];

  // Tab state
  String _activeTab = 'Words'; // 'Words', 'Tenses', 'Numbers'

  // Top Search Bar Translation State
  bool _isSearching = false;
  String _searchQuery = '';
  String _searchResultWord = '';
  String _searchResultMeaning = '';
  String _searchResultPhonetic = '';
  String _searchResultExample = '';
  String _searchResultAudio = '';

  // Tenses State
  List<dynamic> _tensesData = [];
  bool _isLoadingTenses = false;

  // Numbers State
  List<WordItem> _numbersData = [];
  bool _isLoadingNumbers = false;

  // Topics State
  List<dynamic> _topicsData = [];
  Map<String, dynamic>? _selectedTopic;
  bool _isLoadingTopics = false;

  @override
  void initState() {
    super.initState();
    _selectedLevel = (widget.user['level'] ?? 'Beginner').toLowerCase();
    _loadFavorites();
    
    // Check if there is an active tab requested from elsewhere (like home screen)
    final box = Hive.box('vocabulary_box');
    final String? requestedTab = box.get('active_vocab_tab');
    if (requestedTab != null) {
      _activeTab = requestedTab;
      box.delete('active_vocab_tab');
    }

    if (_activeTab == 'favorites') {
      _loadFavorites().then((_) {
        setState(() {
          _loadedWords = List.from(_favoriteWords);
        });
      });
    } else {
      _fetchWords(_selectedLevel);
    }

  }

  @override
  void didUpdateWidget(covariant VocabularyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadFavorites();
    final box = Hive.box('vocabulary_box');
    final String? requestedTab = box.get('active_vocab_tab');
    if (requestedTab != null) {
      setState(() {
        _activeTab = requestedTab;
      });
      box.delete('active_vocab_tab');
      if (requestedTab == 'favorites') {
        _loadFavorites().then((_) {
          setState(() {
            _loadedWords = List.from(_favoriteWords);
          });
        });
      } else if (requestedTab == 'Words') {
        _fetchWords(_selectedLevel);
      } else {
        _fetchWords(requestedTab);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final Box box = Hive.isBoxOpen('vocabulary_box')
          ? Hive.box('vocabulary_box')
          : await Hive.openBox('vocabulary_box');
      final List<dynamic>? favs = box.get('favorites_list');
      if (favs != null) {
        setState(() {
          _favorites.clear();
          _favorites.addAll(favs.cast<String>());
        });
      }
      final dynamic favsDataVal = box.get('favorites_data');
      if (favsDataVal != null) {
        List<dynamic> decoded = [];
        if (favsDataVal is String) {
          decoded = json.decode(favsDataVal);
        } else if (favsDataVal is List) {
          decoded = favsDataVal;
        }
        setState(() {
          _favoriteWords = decoded
              .whereType<Map>()
              .map((e) {
                final map = Map<String, dynamic>.from(e);
                return WordItem.fromJson(map, map['level'] ?? '');
              })
              .toList();
          if (_activeTab == 'favorites') {
            _loadedWords = List.from(_favoriteWords);
          }
        });
      } else {
        setState(() {
          _favoriteWords = [];
          if (_activeTab == 'favorites') {
            _loadedWords = [];
          }
        });
      }
      final List<dynamic>? learned = box.get('learned_words_list');
      if (learned != null) {
        setState(() {
          _learnedWords.clear();
          _learnedWords.addAll(learned.cast<String>());
        });
      }
    } catch (e, s) {
      debugPrint('Error loading favorites: $e\n$s');
    }
  }

  Future<void> _toggleFav(WordItem item) async {
    final w = item.word.trim().toLowerCase();
    final uid = widget.user['uid'];
    setState(() {
      if (_favorites.contains(w)) {
        _favorites.remove(w);
        _favoriteWords.removeWhere((x) => x.word.trim().toLowerCase() == w);
        if (_activeTab == 'favorites') {
          _loadedWords.removeWhere((x) => x.word.trim().toLowerCase() == w);
        }
      } else {
        _favorites.add(w);
        _favoriteWords.insert(0, item); // Store new favorite word above/prepend
        if (_activeTab == 'favorites') {
          _loadedWords.insert(0, item); // Store new favorite word above/prepend
        }
      }
    });
    try {
      final Box box = Hive.isBoxOpen('vocabulary_box')
          ? Hive.box('vocabulary_box')
          : await Hive.openBox('vocabulary_box');
      await box.put('favorites_list', _favorites.toList());
      final serialized = _favoriteWords.map((e) => e.toJson()).toList();
      await box.put('favorites_data', json.encode(serialized));

      if (isFirebaseInitialized && uid != null) {
        final docRef = FirebaseFirestore.instance.collection('favorites').doc('${uid}_$w');
        if (_favorites.contains(w)) {
          await docRef.set({
            'uid': uid,
            'wordId': w,
            'createdAt': FieldValue.serverTimestamp(),
            'word_en': item.word,
            'word_kh': item.meaningKh,
            'example': item.example,
            'level': item.level,
            'phonetic': item.phonetic,
            'audio_url': item.audioUrl,
          });
        } else {
          await docRef.delete();
        }
      }
    } catch (e) { debugPrint('Error toggling favorite in VocabularyScreen: $e'); }
  }

  Future<void> _clearAllFavorites() async {
    setState(() {
      _favorites.clear();
      _favoriteWords.clear();
      if (_activeTab == 'favorites') {
        _loadedWords.clear();
      }
    });
    try {
      final Box box = Hive.isBoxOpen('vocabulary_box')
          ? Hive.box('vocabulary_box')
          : await Hive.openBox('vocabulary_box');
      await box.put('favorites_list', <String>[]);
      await box.put('favorites_data', json.encode([]));

      final uid = widget.user['uid'];
      if (isFirebaseInitialized && uid != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .where('uid', isEqualTo: uid)
            .get();
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) { debugPrint('Error clearing all favorites: $e'); }
  }

  Future<void> _playAudio(String url) async {
    if (url.isEmpty) {
      if (!mounted) return;
      showCustomSnackBar(context, 'Audio pronunciation not available.');
      return;
    }
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (e) { debugPrint('Error playing audio in VocabularyScreen: $e'); }
  }

  // Fetch and enrich 25 daily words
  Future<void> _fetchWords(String level, {bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      if (level == 'beginner' || level == 'intermediate' || level == 'advanced') {
        _selectedLevel = level;
      }
      _loadedWords = [];
    });

    try {
      final Box box = Hive.isBoxOpen('vocabulary_box')
          ? Hive.box('vocabulary_box')
          : await Hive.openBox('vocabulary_box');

      final todayStr = DateTime.now().toIso8601String().split('T')[0]; // yyyy-MM-dd
      final todayKey = "daily_words_${todayStr}_$level";

      // 1. Check Date Cache
      if (!forceRefresh && box.containsKey(todayKey)) {
        final cachedString = box.get(todayKey);
        if (cachedString != null) {
          try {
            final List<dynamic> cachedList = json.decode(cachedString);
            if (!mounted) return;
            setState(() {
              _loadedWords = cachedList
                  .map((item) => WordItem.fromJson(Map<String, dynamic>.from(item), level))
                  .toList();
              _isLoading = false;
            });
            return;
          } catch (e) { debugPrint('Error decoding cached words: $e'); }
        }
      }

      // 2. Load Local Asset JSON
      List<dynamic> levelWords = [];
      if (level == 'nouns' || level == 'pronouns' || level == 'verbs' || level == 'adjectives') {
        String assetPath = '';
        if (level == 'nouns') assetPath = 'assets/data/api_vocabulary_nouns.json';
        if (level == 'pronouns') assetPath = 'assets/data/api_vocabulary_pronoun.json';
        if (level == 'verbs') assetPath = 'assets/data/api_vocabulary_verbs.json';
        if (level == 'adjectives') assetPath = 'assets/data/api_vocabulary_adjective.json';
        
        final jsonStr = await rootBundle.loadString(assetPath);
        levelWords = json.decode(jsonStr);
      } else {
        final jsonStr = await rootBundle.loadString('assets/data/api_vocabulary.json');
        final Map<String, dynamic> data = json.decode(jsonStr);
        levelWords = data[level] ?? [];
      }

      if (levelWords.isEmpty) {
        throw Exception("No words found for level $level");
      }

      // 3. Select 25 Random Words
      final allWords = List<Map<String, dynamic>>.from(
        levelWords.map((e) => Map<String, dynamic>.from(e))
      );
      allWords.shuffle();
      final selected = allWords.take(25).toList();

      List<WordItem> enrichedWords = selected.map((w) {
        return WordItem.fromJson(w, level);
      }).toList();

      // Save to cache
      final serialized = enrichedWords.map((e) => e.toJson()).toList();
      await box.put(todayKey, json.encode(serialized));

      if (!mounted) return;
      setState(() {
        _loadedWords = enrichedWords;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      showCustomSnackBar(context, 'Failed to load words: $e');
    }
  }

  // Load tenses data
  Future<void> _loadTensesData() async {
    if (_tensesData.isNotEmpty) return;
    setState(() {
      _isLoadingTenses = true;
    });
    try {
      final jsonStr = await rootBundle.loadString('assets/data/api_english_tenses.json');
      final List<dynamic> decoded = json.decode(jsonStr);
      if (!mounted) return;
      setState(() {
        _tensesData = decoded;
        _isLoadingTenses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTenses = false;
      });
    }
  }

  // Load numbers data
  Future<void> _loadNumbersData() async {
    if (_numbersData.isNotEmpty) return;
    setState(() {
      _isLoadingNumbers = true;
    });
    try {
      final jsonStr = await rootBundle.loadString('assets/data/api_vocabulary_number.json');
      final List<dynamic> decoded = json.decode(jsonStr);
      if (!mounted) return;
      setState(() {
        _numbersData = List<WordItem>.from(decoded.map((item) {
          final mapItem = item as Map<String, dynamic>;
          return WordItem(
            word: mapItem['word_en'] ?? '',
            meaningKh: mapItem['meaning_kh'] ?? '',
            example: mapItem['example'] ?? '',
            level: 'NUMBERS',
            phonetic: mapItem['phonetic'] ?? '',
            audioUrl: mapItem['audio'] ?? mapItem['audio_url'] ?? '',
          );
        }));
        _isLoadingNumbers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingNumbers = false;
      });
    }
  }

  // Load topics data
  Future<void> _loadTopicsData({bool forceRefresh = false}) async {
    if (_topicsData.isNotEmpty && !forceRefresh) {
      if (_selectedTopic == null && _topicsData.isNotEmpty) {
        setState(() {
          _topicsData.shuffle();
          _selectedTopic = _topicsData.first;
        });
      }
      return;
    }
    setState(() {
      _isLoadingTopics = true;
    });
    try {
      final jsonStr = await rootBundle.loadString('assets/data/api_english_topics.json');
      final List<dynamic> decoded = json.decode(jsonStr);
      if (!mounted) return;
      setState(() {
        _topicsData = decoded;
        if (_topicsData.isNotEmpty) {
          final List<dynamic> list = List.from(_topicsData);
          list.shuffle();
          _selectedTopic = list.first;
        } else {
          _selectedTopic = null;
        }
        _isLoadingTopics = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTopics = false;
      });
    }
  }

  // Top Search Bar real-time translation logic
  void _onSearchTextChanged(String text) {
    setState(() {
      _searchQuery = text;
    });

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResultWord = '';
        _searchResultMeaning = '';
        _searchResultPhonetic = '';
        _searchResultExample = '';
        _searchResultAudio = '';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performSearchTranslation(text);
    });
  }

  Future<void> _performSearchTranslation(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final hasKhmer = RegExp(r'[\u1780-\u17FF]').hasMatch(cleanText);
      final sl = hasKhmer ? 'km' : 'en';
      final tl = hasKhmer ? 'en' : 'km';

      // 1. Google Translate API
      final transUri = Uri.parse(
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sl&tl=$tl&dt=t&q=${Uri.encodeComponent(cleanText)}');
      final transRes = await http.get(transUri).timeout(const Duration(seconds: 4));
      
      String translatedText = '';
      if (transRes.statusCode == 200) {
        final transData = json.decode(transRes.body);
        translatedText = transData[0][0][0] ?? '';
      }

      final englishWord = hasKhmer ? translatedText : cleanText;
      final khmerTranslation = hasKhmer ? cleanText : translatedText;

      // 2. Free Dictionary API
      String phonetic = '/.../';
      String example = '"..."';
      String audioUrl = '';

      if (englishWord.isNotEmpty && RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(englishWord)) {
        try {
          final dictRes = await http.get(Uri.parse(
              'https://api.dictionaryapi.dev/api/v2/entries/en/${englishWord.split(' ')[0]}'))
              .timeout(const Duration(seconds: 4));
          if (dictRes.statusCode == 200) {
            final dictData = json.decode(dictRes.body);
            if (dictData is List && dictData.isNotEmpty) {
              final entry = dictData[0];
              phonetic = entry['phonetic'] ?? '';
              
              if (entry['phonetics'] != null) {
                final audioObj = entry['phonetics'].firstWhere(
                  (p) =>
                      p['audio'] != null &&
                      p['audio'].toString().startsWith('http'),
                  orElse: () => null,
                );
                if (audioObj != null) {
                  audioUrl = audioObj['audio'] ?? '';
                }
              }
              if (phonetic.isEmpty && entry['phonetics'] != null && entry['phonetics'].isNotEmpty) {
                for (final p in entry['phonetics']) {
                  if (p['text'] != null && p['text'].toString().isNotEmpty) {
                    phonetic = p['text'];
                    break;
                  }
                }
              }

              if (entry['meanings'] != null && entry['meanings'].isNotEmpty) {
                bool foundExample = false;
                for (final meaning in entry['meanings']) {
                  if (meaning['definitions'] != null) {
                    for (final def in meaning['definitions']) {
                      if (def['example'] != null && def['example'].toString().isNotEmpty) {
                        example = def['example'].toString();
                        foundExample = true;
                        break;
                      }
                    }
                  }
                  if (foundExample) break;
                }
              }
            }
          }
        } catch (e) { debugPrint('Error fetching dictionary data in search: $e'); }
      }

      if (phonetic.isEmpty) {
        phonetic = '/.../';
      } else {
        if (!phonetic.startsWith('/')) phonetic = '/$phonetic';
        if (!phonetic.endsWith('/')) phonetic = '$phonetic/';
      }
      if (example.isEmpty || example == '"..."') {
        example = '"..."';
      } else {
        if (example.startsWith('"') && example.endsWith('"')) {
          example = example.substring(1, example.length - 1);
        }
      }

      setState(() {
        _searchResultWord = englishWord;
        _searchResultMeaning = khmerTranslation;
        _searchResultPhonetic = phonetic;
        _searchResultExample = example;
        _searchResultAudio = audioUrl;
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4F46E5);
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);
    final isSearchActive = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            GestureDetector(
              onTap: widget.onOpenDrawer,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFEEF0FF),
                ),
                child: const Icon(Icons.book,
                    color: Color(0xFF4F46E5), size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Words',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Learning vocabulary',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar Container
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchTextChanged,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search words...',
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Tab pills row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['Words', 'favorites', 'nouns', 'pronouns', 'verbs', 'adjectives', 'Tenses', 'Numbers', 'Topics'].map((tab) {
                    final isSelected = _activeTab == tab;
                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          _activeTab = tab;
                        });
                        if (tab == 'Topics') {
                          _loadTopicsData();
                        } else if (tab == 'Tenses') {
                          _loadTensesData();
                        } else if (tab == 'Numbers') {
                          _loadNumbersData();
                        } else if (tab == 'favorites') {
                          await _loadFavorites();
                          setState(() {
                            _loadedWords = List.from(_favoriteWords);
                          });
                        } else if (tab == 'Words') {
                          await _loadFavorites();
                          _fetchWords(_selectedLevel);
                        } else {
                          await _loadFavorites();
                          _fetchWords(tab);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          // Capitalize first letter for display
                          tab == 'favorites'
                              ? 'Favorites'
                              : tab == 'nouns'
                                  ? 'Nouns'
                                  : tab == 'pronouns'
                                      ? 'Pronouns'
                                      : tab == 'verbs'
                                          ? 'Verbs'
                                          : tab == 'adjectives'
                                              ? 'Adjectives'
                                              : tab == 'Topics'
                                                  ? 'Topics'
                                                  : tab,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Vocabulary/Tenses Scrollable Container Block
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header inside card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _activeTab == 'Tenses'
                                ? 'Tenses 12 In English'
                                : _activeTab == 'favorites'
                                    ? 'Favorites'
                                    : _activeTab == 'nouns'
                                        ? 'Nouns'
                                        : _activeTab == 'pronouns'
                                            ? 'Pronouns'
                                            : _activeTab == 'verbs'
                                                ? 'Verbs'
                                                : _activeTab == 'adjectives'
                                                    ? 'Adjectives'
                                                    : _activeTab == 'Topics'
                                                        ? 'Topics'
                                                        : _activeTab,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Refresh Button (show for Words, nouns, pronouns, verbs, adjectives)
                        if (_activeTab == 'Words' ||
                            _activeTab == 'nouns' ||
                            _activeTab == 'pronouns' ||
                            _activeTab == 'verbs' ||
                            _activeTab == 'adjectives' ||
                            _activeTab == 'Topics')
                          GestureDetector(
                            onTap: () {
                              if (_activeTab == 'Topics') {
                                _loadTopicsData(forceRefresh: true);
                              } else if (!isSearchActive && !_isLoading) {
                                if (_activeTab == 'Words') {
                                  _fetchWords(_selectedLevel, forceRefresh: true);
                                } else {
                                  _fetchWords(_activeTab, forceRefresh: true);
                                }
                                
                                String tabKey = _activeTab;
                                if (tabKey == 'adjectives') {
                                  tabKey = 'adjective';
                                }
                                final catKey = 'refresh_$tabKey';
                                
                                final catCount = int.tryParse(widget.user[catKey] ?? '0') ?? 0;
                                
                                int getLvl(int ref) {
                                  if (ref < 1) return 0;
                                  int lvl = 1;
                                  int req = 1;
                                  while (req * 2 <= ref) {
                                    req *= 2;
                                    lvl++;
                                  }
                                  return lvl;
                                }
                                
                                final oldLevel = getLvl(catCount);
                                final newLevel = getLvl(catCount + 1);

                                widget.user[catKey] = (catCount + 1).toString();
                                
                                final currentCount = int.tryParse(widget.user['refreshCount'] ?? '0') ?? 0;
                                widget.user['refreshCount'] = (currentCount + 1).toString();
                                
                                try {
                                  final box = Hive.box('vocabulary_box');
                                  box.put('user_profile', widget.user);
                                } catch (e) { debugPrint('Error saving user profile on refresh: $e'); }
                                
                                final uid = widget.user['uid'];
                                if (newLevel > oldLevel) {
                                  final categoryName = _activeTab == 'Words' ? 'Words Vocabulary' : _activeTab;
                                  addAppNotification(
                                    title: 'New Level Unlocked! 🚀',
                                    body: 'Congratulations! Your $categoryName level has increased to Level $newLevel!',
                                    iconName: 'level',
                                    uid: uid,
                                  );
                                }

                                if (uid != null && isFirebaseInitialized) {
                                  FirebaseFirestore.instance.collection('users').doc(uid).update({
                                    catKey: catCount + 1,
                                    'refreshCount': currentCount + 1,
                                  }).catchError((e) { debugPrint('Error updating refresh count in Firestore: $e'); });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF0FF),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.refresh, color: primaryColor, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Refresh',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_activeTab == 'favorites')
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'Clear All Favorites',
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                    ),
                                    content: const Text('Are you sure you want to remove all words from your favorites?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _clearAllFavorites();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Clear All',
                                          style: GoogleFonts.inter(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_sweep, color: Color(0xFFEF4444), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Clear All',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ScrollView content inside the container
                    if (_activeTab == 'Topics')
                      _isLoadingTopics
                          ? Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            )
                          : _selectedTopic == null
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'Failed to load topic.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF0FF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: primaryColor.withOpacity(0.12),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.topic,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _selectedTopic!['topic_title'] ?? 'No Title',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _selectedTopic!['topic_text'] ?? '',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              height: 1.6,
                                              color: const Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                    else if (_activeTab == 'Numbers')
                      _isLoadingNumbers
                          ? Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            )
                          : _numbersData.isEmpty
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'Failed to load numbers.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _numberGroups.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    color: Color(0xFFF1F5F9),
                                    thickness: 1,
                                    height: 20,
                                  ),
                                  itemBuilder: (context, index) {
                                    final group = _numberGroups[index];
                                    return _buildNumberGroupCard(group, primaryColor);
                                  },
                                )
                    else if (_activeTab == 'Tenses')
                      _isLoadingTenses
                          ? Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            )
                          : _tensesData.isEmpty
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                    'Failed to load tenses.',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _tensesData.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    color: Color(0xFFF1F5F9),
                                    thickness: 1,
                                    height: 20, // Clean vertical spacing around the divider
                                  ),
                                  itemBuilder: (context, index) {
                                    final tense = _tensesData[index];
                                    return _buildTenseCard(tense, primaryColor);
                                  },
                                )
                    else // Words tab
                      isSearchActive
                          ? _buildSearchTranslationResult(primaryColor)
                          : _isLoading
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 60),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                  ),
                                )
                              : _loadedWords.isEmpty
                                  ? Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        'No words loaded.',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _loadedWords.length,
                                      itemBuilder: (context, index) {
                                        final item = _loadedWords[index];
                                        return _buildWordCard(item, primaryColor);
                                      },
                                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard(WordItem item, Color primaryColor) {
    final isSaved = _favorites.contains(item.word.trim().toLowerCase());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  // English word
                  Flexible(
                    child: Text(
                      item.word,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Phonetic
                  Flexible(
                    child: Text(
                      item.phonetic,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Pronunciation Speaker Icon
                  if (item.audioUrl.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _playAudio(item.audioUrl),
                      icon: Icon(Icons.volume_up, color: primaryColor, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Favorite Heart Icon
            GestureDetector(
              onTap: () => _toggleFav(item),
              child: Icon(
                isSaved ? Icons.favorite : Icons.favorite_border,
                color: isSaved ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Khmer meaning
        Text(
          item.meaningKh,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        // Example sentence
        Text(
          item.example.isEmpty || item.example == '"..."' ? '"..."' : '"${item.example}"',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF334155),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        const Divider(color: Color(0xFFF1F5F9), thickness: 1),
      ],
    );
  }

  Widget _buildTenseCard(Map<String, dynamic> tense, Color primaryColor) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tense['tense_name'] ?? '',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tense['meaning_kh'] ?? '',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: primaryColor,
              size: 20,
            ),
          ),
          children: [
            const SizedBox(height: 8),
            // Usage description displayed inside expanded state
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tense['usage'] ?? '',
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tense['usage_kh'] ?? '',
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            _buildTenseFormulaSection('Positive', tense['positive'], primaryColor),
            const SizedBox(height: 12),
            _buildTenseFormulaSection('Negative', tense['negative'], primaryColor),
            const SizedBox(height: 12),
            _buildTenseFormulaSection('Question', tense['question'], primaryColor),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTenseFormulaSection(String label, Map<String, dynamic>? formulaData, Color primaryColor) {
    if (formulaData == null) return const SizedBox.shrink();

    final formula = formulaData['formula'] ?? '';
    final List<dynamic> examples = formulaData['examples'] ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formula,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...examples.map((ex) {
              final sentence = ex['sentence'] ?? '';
              final meaningKh = ex['meaning_kh'] ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.black54)),
                        Expanded(
                          child: Text(
                            sentence,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, top: 1.0),
                      child: Text(
                        meaningKh,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchTranslationResult(Color primaryColor) {
    if (_isSearching) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      );
    }

    if (_searchResultWord.isEmpty && _searchResultMeaning.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Type a word to view real-time translation results.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
      );
    }

    final searchItem = WordItem(
      word: _searchResultWord,
      meaningKh: _searchResultMeaning,
      example: _searchResultExample,
      level: 'SEARCH',
      phonetic: _searchResultPhonetic,
      audioUrl: _searchResultAudio,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWordCard(searchItem, primaryColor),
      ],
    );
  }

  final List<NumberGroup> _numberGroups = const [
    NumberGroup(title: "1 - 10 (One - Ten)", meaningKh: "មួយ ទៅ ដប់", startIndex: 0, endIndex: 10),
    NumberGroup(title: "11 - 20 (Eleven - Twenty)", meaningKh: "ដប់មួយ ទៅ ម្ភៃ", startIndex: 10, endIndex: 20),
    NumberGroup(title: "21 - 30 (Twenty-one - Thirty)", meaningKh: "ម្ភៃមួយ ទៅ សាមសិប", startIndex: 20, endIndex: 30),
    NumberGroup(title: "31 - 40 (Thirty-one - Forty)", meaningKh: "សាមសិបមួយ ទៅ សែសិប", startIndex: 30, endIndex: 40),
    NumberGroup(title: "41 - 50 (Forty-one - Fifty)", meaningKh: "សែសិបមួយ ទៅ ហាសិប", startIndex: 40, endIndex: 50),
    NumberGroup(title: "51 - 60 (Fifty-one - Sixty)", meaningKh: "ហាសិបមួយ ទៅ ហុកសិប", startIndex: 50, endIndex: 60),
    NumberGroup(title: "61 - 70 (Sixty-one - Seventy)", meaningKh: "ហុកសិបមួយ ទៅ ចិតសិប", startIndex: 60, endIndex: 70),
    NumberGroup(title: "71 - 80 (Seventy-one - Eighty)", meaningKh: "ចិតសិបមួយ ទៅ ប៉ែតសិប", startIndex: 70, endIndex: 80),
    NumberGroup(title: "81 - 90 (Eighty-one - Ninety)", meaningKh: "ប៉ែតសិបមួយ ទៅ កៅសិប", startIndex: 80, endIndex: 90),
    NumberGroup(title: "91 - 100 (Ninety-one - One Hundred)", meaningKh: "កៅសិបមួយ ទៅ មួយរយ", startIndex: 90, endIndex: 100),
    NumberGroup(title: "Hundreds (200 - 900)", meaningKh: "ពីររយ ទៅ ប្រាំបួនរយ", startIndex: 100, endIndex: 109),
    NumberGroup(title: "Thousands & Millions (1,000 - 1 Billion)", meaningKh: "ពាន់ ម៉ឺន សែន លាន ប៊ីលាន", startIndex: 109, endIndex: 121),
    NumberGroup(title: "Ordinals: 1st - 10th", meaningKh: "លំដាប់ទី ១ ទៅ ទី ១០", startIndex: 121, endIndex: 131),
    NumberGroup(title: "Ordinals: 11th - 20th", meaningKh: "លំដាប់ទី ១១ ទៅ ទី ២០", startIndex: 131, endIndex: 141),
    NumberGroup(title: "Ordinals: 30th - Millionth", meaningKh: "លំដាប់ទី ៣០ ទៅ ទី ១ លាន", startIndex: 141, endIndex: 152),
  ];

  Widget _buildNumberGroupCard(NumberGroup group, Color primaryColor) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                group.meaningKh,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFEEF0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: primaryColor,
              size: 20,
            ),
          ),
          children: [
            const SizedBox(height: 8),
            ..._numbersData
                .sublist(
                  group.startIndex.clamp(0, _numbersData.length),
                  group.endIndex.clamp(0, _numbersData.length),
                )
                .map((item) => _buildWordCard(item, primaryColor)),
          ],
        ),
      ),
    );
  }
}
