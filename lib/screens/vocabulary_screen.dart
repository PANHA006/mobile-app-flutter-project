import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WordItem {
  final int id;
  final String word;
  final String meaning;
  final String example;
  final String level;
  final String category;

  const WordItem({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    required this.level,
    required this.category,
  });
}

const List<WordItem> WORDS = [
  WordItem(id: 1, word: 'Eloquent', meaning: 'Fluent and persuasive in speaking or writing.', example: 'She gave an eloquent speech.', level: 'B2', category: 'Academic'),
  WordItem(id: 2, word: 'Resilient', meaning: 'Able to recover quickly from difficulties.', example: 'He remained resilient through hardship.', level: 'B2', category: 'Character'),
  WordItem(id: 3, word: 'Ambiguous', meaning: 'Open to more than one interpretation.', example: 'The instruction was ambiguous.', level: 'C1', category: 'Academic'),
  WordItem(id: 4, word: 'Diligent', meaning: 'Showing careful and persistent effort.', example: 'She is a diligent student.', level: 'B1', category: 'Character'),
  WordItem(id: 5, word: 'Innovative', meaning: 'Featuring new methods or ideas.', example: 'The company launched an innovative product.', level: 'B2', category: 'Business'),
  WordItem(id: 6, word: 'Profound', meaning: 'Having deep insight or intensity.', example: 'A profound change in attitude.', level: 'C1', category: 'Academic'),
  WordItem(id: 7, word: 'Meticulous', meaning: 'Showing great attention to detail.', example: 'He was meticulous in his research.', level: 'C1', category: 'Character'),
  WordItem(id: 8, word: 'Concise', meaning: 'Giving a lot of information in few words.', example: 'Please be concise in your answer.', level: 'B1', category: 'Academic'),
  WordItem(id: 9, word: 'Empathy', meaning: 'The ability to understand others\' feelings.', example: 'She showed great empathy to her friend.', level: 'B2', category: 'Emotion'),
  WordItem(id: 10, word: 'Pragmatic', meaning: 'Dealing with things sensibly and realistically.', example: 'A pragmatic approach to solving problems.', level: 'C1', category: 'Character'),
  WordItem(id: 11, word: 'Versatile', meaning: 'Able to adapt to many functions.', example: 'She is a versatile musician.', level: 'B2', category: 'Character'),
  WordItem(id: 12, word: 'Integrity', meaning: 'The quality of being honest and having principles.', example: 'He acted with integrity throughout.', level: 'B2', category: 'Character'),
];

const Map<String, Color> levelBgs = {
  'B1': Color(0xFFDBEAFE),
  'B2': Color(0xFFEDE9FE),
  'C1': Color(0xFFFEF3C7),
};

const Map<String, Color> levelTexts = {
  'B1': Color(0xFF1E3A8A),
  'B2': Color(0xFF4C1D95),
  'C1': Color(0xFF92400E),
};

const Map<String, String> aiExplanations = {
  'Eloquent': 'Think of \'eloquent\' as the upgrade to \'good speaker\'. When someone speaks eloquently, their words flow smoothly and powerfully, convincing people and painting vivid pictures.',
  'Resilient': '\'Resilient\' comes from rubber — it bounces back! A resilient person faces problems, bends a bit, but springs right back to normal.',
  'Ambiguous': 'Something ambiguous is like a shadow — you\'re not sure what it is. The same sentence or situation could mean two different things.',
};

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  String _search = '';
  final Set<int> _favorites = {1, 3};
  String _tab = 'all'; // 'all', 'favorites'
  final _searchController = TextEditingController();

  void _toggleFav(int id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  void _showDetailModal(WordItem w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F8FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isSaved = _favorites.contains(w.id);
            final aiExpl = aiExplanations[w.word];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      // Header panel
                      Container(
                        width: double.infinity,
                        color: const Color(0xFF4F46E5),
                        padding: const EdgeInsets.only(top: 24, bottom: 40, left: 20, right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                w.category,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              w.word,
                              style: GoogleFonts.outfit(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: levelBgs[w.level] ?? const Color(0xFFEDE9FE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    w.level,
                                    style: GoogleFonts.outfit(
                                      color: levelTexts[w.level] ?? const Color(0xFF4C1D95),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.volume_up, color: Colors.white.withOpacity(0.7), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Pronounce',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Details
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildSection('Meaning', w.meaning),
                            const SizedBox(height: 16),
                            _buildSection('Example', '"${w.example}"', italic: true),
                            const SizedBox(height: 16),

                            if (aiExpl != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF0FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: const Border(
                                    left: BorderSide(color: Color(0xFF4F46E5), width: 3.5),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          'AI Explanation',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF4F46E5),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      aiExpl,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF0F0E2A),
                                        fontSize: 13,
                                        height: 1.65,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _toggleFav(w.id);
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isSaved ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5).withOpacity(0.12),
                                      ),
                                      backgroundColor: isSaved ? const Color(0xFFFFFBEB) : Colors.white,
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    icon: Icon(
                                      isSaved ? Icons.star : Icons.star_border,
                                      color: isSaved ? const Color(0xFFF59E0B) : const Color(0xFF6B6B8A),
                                      size: 20,
                                    ),
                                    label: Text(
                                      isSaved ? 'Saved' : 'Save',
                                      style: GoogleFonts.outfit(
                                        color: isSaved ? const Color(0xFFF59E0B) : const Color(0xFF6B6B8A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: Text(
                                      'Got it!',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSection(String title, String content, {bool italic = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              color: const Color(0xFF4F46E5),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F0E2A),
              fontSize: 14,
              height: 1.6,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5);
    final secondaryColor = const Color(0xFFEEF0FF);
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);

    final filtered = WORDS.where((w) {
      final q = _search.toLowerCase();
      final matches = w.word.toLowerCase().contains(q) || w.meaning.toLowerCase().contains(q);
      if (_tab == 'favorites') {
        return matches && _favorites.contains(w.id);
      }
      return matches;
    }).toList();

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vocabulary',
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${WORDS.length} words • ${_favorites.length} saved',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                children: [
                  // Search field
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF6B6B8A), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _search = val;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: 'Search words...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_search.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _search = '';
                              });
                            },
                            child: const Icon(Icons.close, color: Color(0xFF6B6B8A), size: 18),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tab switcher
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFECECF5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _tab = 'all';
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _tab == 'all' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _tab == 'all'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: Text(
                                'All Words',
                                style: GoogleFonts.outfit(
                                  color: _tab == 'all' ? primaryColor : const Color(0xFF6B6B8A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _tab = 'favorites';
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _tab == 'favorites' ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _tab == 'favorites'
                                    ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))]
                                    : null,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              child: Text(
                                '⭐ Saved (${_favorites.length})',
                                style: GoogleFonts.outfit(
                                  color: _tab == 'favorites' ? primaryColor : const Color(0xFF6B6B8A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Word list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No words found.',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6B6B8A),
                                fontSize: 15,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemBuilder: (context, index) {
                              final w = filtered[index];
                              final isSaved = _favorites.contains(w.id);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cardBorderColor),
                                ),
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () => _showDetailModal(w),
                                  title: Row(
                                    children: [
                                      Text(
                                        w.word,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: const Color(0xFF0F0E2A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: levelBgs[w.level] ?? const Color(0xFFEDE9FE),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          w.level,
                                          style: GoogleFonts.inter(
                                            color: levelTexts[w.level] ?? const Color(0xFF4C1D95),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      w.meaning,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF6B6B8A),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () => _toggleFav(w.id),
                                        icon: Icon(
                                          isSaved ? Icons.star : Icons.star_border,
                                          color: isSaved ? const Color(0xFFF59E0B) : const Color(0xFF6B6B8A),
                                          size: 20,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF6B6B8A)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
