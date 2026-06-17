import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, String> user;
  final Function(int) onNavigate;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onNavigate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _translateController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  // Translator state
  String _sourceLang = 'en';
  String _targetLang = 'km';
  String _translationResult = ''; 
  String _phonetic = '';
  String _audioUrl = '';
  String _example = '';
  bool _isTranslating = false;

  final Set<String> _homeFavorites = {'computer'};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _translateController.text = '';
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final Box box = Hive.isBoxOpen('vocabulary_box')
          ? Hive.box('vocabulary_box')
          : await Hive.openBox('vocabulary_box');
      // Sync local favorite set with Hive cache if needed
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _translateController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
    });
    _onTextChanged(_translateController.text);
  }

  void _onTextChanged(String text) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _performTranslation(text);
    });
  }

  Future<void> _performTranslation(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      setState(() {
        _translationResult = '';
        _phonetic = '';
        _audioUrl = '';
        _example = '';
        _isTranslating = false;
      });
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      final transUri = Uri.parse(
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$_sourceLang&tl=$_targetLang&dt=t&q=${Uri.encodeComponent(cleanText)}');
      final transRes =
          await http.get(transUri).timeout(const Duration(seconds: 5));
      if (transRes.statusCode == 200) {
        final transData = json.decode(transRes.body);
        final translation = transData[0][0][0] ?? '';

        final englishWordForDict =
            _sourceLang == 'en' ? cleanText : translation;

        String phonetic = '';
        String audioUrl = '';
        String example = '';

        if (englishWordForDict.isNotEmpty &&
            RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(englishWordForDict)) {
          try {
            final dictRes = await http
                .get(Uri.parse(
                    'https://api.dictionaryapi.dev/api/v2/entries/en/${englishWordForDict.split(' ')[0]}'))
                .timeout(const Duration(seconds: 3));

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

                if (entry['meanings'] != null && entry['meanings'].isNotEmpty) {
                  for (final meaning in entry['meanings']) {
                    if (meaning['definitions'] != null &&
                        meaning['definitions'].isNotEmpty) {
                      example = meaning['definitions'][0]['example'] ?? '';
                      if (example.isNotEmpty) break;
                    }
                  }
                }
              }
            }
          } catch (_) {}
        }

        setState(() {
          _translationResult = translation;
          _phonetic = phonetic;
          _audioUrl = audioUrl;
          _example = example;
          _isTranslating = false;
        });
      } else {
        setState(() {
          _isTranslating = false;
        });
      }
    } catch (_) {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  Future<void> _playAudio(String url) async {
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio pronunciation not available.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {}
  }

  void _toggleFav(String word) {
    if (word.isEmpty) return;
    setState(() {
      final w = word.toLowerCase();
      if (_homeFavorites.contains(w)) {
        _homeFavorites.remove(w);
      } else {
        _homeFavorites.add(w);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by KeepAliveClientMixin

    final primaryColor = const Color(0xFF4F46E5);
    final statsBorderColor = const Color(0xFF4F46E5).withOpacity(0.08);

    final firstName = widget.user['name']?.split(' ')[0] ?? 'Student';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final stats = [
      {
        'label': 'Words learned',
        'value': '128',
        'icon': Icons.trending_up,
        'color': const Color(0xFF4F46E5),
        'glow': const Color(0xFFEEF0FF)
      },
      {
        'label': 'Day streak',
        'value': '12',
        'icon': Icons.emoji_events,
        'color': const Color(0xFFF59E0B),
        'glow': const Color(0xFFFFFBEB)
      },
      {
        'label': 'Mins today',
        'value': '24',
        'icon': Icons.access_time,
        'color': const Color(0xFF0891B2),
        'glow': const Color(0xFFECFEFF)
      },
    ];

    final categories = [
      {
        'label': 'Vocabulary',
        'desc': 'Master 10k+ words',
        'icon': Icons.book_outlined,
        'color': const Color(0xFF4F46E5),
        'bg': const Color(0xFFEEF0FF),
        'tab': 1
      },
      {
        'label': 'AI Chat',
        'desc': 'Converse with AI',
        'icon': Icons.chat_bubble_outline,
        'color': const Color(0xFF0891B2),
        'bg': const Color(0xFFECFEFF),
        'tab': 2
      },
      {
        'label': 'Daily Quiz',
        'desc': 'Test your progress',
        'icon': Icons.bolt_outlined,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFFBEB),
        'tab': 1
      },
      {
        'label': 'Favorites',
        'desc': 'Your starred words',
        'icon': Icons.star_outline,
        'color': const Color(0xFFEC4899),
        'bg': const Color(0xFFFDF2F8),
        'tab': 1
      },
    ];

    final currentInput = _translateController.text.trim().toLowerCase();
    final isSaved = _homeFavorites.contains(currentInput);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 96,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 44,
                    color: primaryColor,
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: Colors.amber[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 5),
                  Text(
                    '$greeting,',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$firstName! 👋',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF0F172A),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Let\'s practice your English today!',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18.0),
            child: GestureDetector(
              onTap: () => widget.onNavigate(4), // navigate to profile
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEEF0FF),
                  border: Border.all(
                      color: const Color(0xFF4F46E5).withOpacity(0.12),
                      width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Daily progress banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: primaryColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Study Goal',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '80%',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: 0.8,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Almost there! Study for 6 more minutes to hit your goal.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  Row(
                    children: stats.map((s) {
                      final color = s['color'] as Color;
                      final glow = s['glow'] as Color;
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: statsBorderColor),
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
                                      color: glow,
                                    ),
                                    child: Icon(s['icon'] as IconData,
                                        color: color, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      s['value'] as String,
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
                                s['label'] as String,
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
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Real-time Translate Card
                  GestureDetector(
                    onTap: () {
                      _focusNode.requestFocus();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                          left: 22, right: 22, top: 18, bottom: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, const Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 240,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Card Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.15)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.translate,
                                              color: Colors.white, size: 12),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Translate',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Flag English + Khmer + Swap button
                                    GestureDetector(
                                      onTap: _swapLanguages,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          border: Border.all(
                                              color: Colors.white.withOpacity(0.15)),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              _sourceLang == 'en'
                                                  ? '🇬🇧 EN'
                                                  : '🇰🇭 KH',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 4.0),
                                              child: Icon(Icons.swap_horiz,
                                                  color: Colors.white,
                                                  size: 12),
                                            ),
                                            Text(
                                              _targetLang == 'en'
                                                  ? '🇬🇧 EN'
                                                  : '🇰🇭 KH',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _toggleFav(_translateController.text),
                                  icon: Icon(
                                    isSaved ? Icons.star : Icons.star_border,
                                    color: isSaved
                                        ? const Color(0xFFF59E0B)
                                        : Colors.white,
                                    size: 24,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            // Input field for translating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 75,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        TextField(
                                          controller: _translateController,
                                          focusNode: _focusNode,
                                          onChanged: _onTextChanged,
                                          cursorColor: Colors.white,
                                          style: GoogleFonts.outfit(
                                            fontSize: 34,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: _sourceLang == 'en'
                                                ? 'Type English...'
                                                : 'វាយបញ្ចូលពាក្យខ្មែរ...',
                                            hintStyle: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5)),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _phonetic.isNotEmpty ? _phonetic : '/.../',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color:
                                                Colors.white.withOpacity(0.65),
                                            fontSize: 14.5,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _playAudio(_audioUrl),
                                  child: Container(
                                    width: 35,
                                    height: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.volume_up,
                                        color: Colors.white, size: 18),
                                  ),
                                ),
                              ],
                            ),
                            // Translation result and example sentence column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isTranslating)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                else
                                  Text(
                                    _translationResult.isNotEmpty
                                        ? _translationResult
                                        : '...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFFFCD34D),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      height: 1.8,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  _example.isNotEmpty ? '"$_example"' : '"..."',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: const Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 13.5,
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Categories Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Learning Features',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'View All',
                        style: GoogleFonts.inter(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid of categories
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.7,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final color = cat['color'] as Color;
                      final bg = cat['bg'] as Color;
                      final tab = cat['tab'] as int;

                      return GestureDetector(
                        onTap: () => widget.onNavigate(tab),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: color.withOpacity(0.18),
                                      width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(cat['icon'] as IconData,
                                    color: color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      cat['label'] as String,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cat['desc'] as String,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF64748B),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // AI Chat CTA Banner
                  GestureDetector(
                    onTap: () => widget.onNavigate(2), // go to AI chat
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF06B6D4).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ask Smart AI Tutor',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Grammar help, translation & explanations',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward_ios,
                                size: 12, color: Colors.white),
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
      ),
    );
  }
}
