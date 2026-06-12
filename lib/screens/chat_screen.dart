import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Message {
  final int id;
  final String role; // 'user' | 'ai'
  final String text;
  final String time;

  const Message({
    required this.id,
    required this.role,
    required this.text,
    required this.time,
  });
}

const List<String> SUGGESTED = [
  'What does \'resilient\' mean?',
  'Correct my grammar: She don\'t like coffee',
  'Give me 5 business English phrases',
  'What\'s the difference between \'affect\' and \'effect\'?',
  'Explain the present perfect tense',
];

const Map<String, String> aiResponses = {
  'default': 'Great question! I\'m here to help you improve your English. Ask me about vocabulary, grammar, pronunciation, or sentence structure.',
  'resilient': '**Resilient** means able to recover quickly from difficulties or tough situations. Think of it like a rubber band — it stretches but bounces back!\n\n📌 Example: "Despite failing twice, she remained resilient and kept trying."\n\n💡 Related words: *tenacious*, *adaptable*, *tough*',
  'grammar': 'Here\'s the correction:\n\n❌ *She don\'t like coffee*\n✅ **She doesn\'t like coffee**\n\n**Why?** With third-person singular (he/she/it), we use **doesn\'t** (does + not) instead of **don\'t**.',
  'business': 'Here are 5 essential business English phrases:\n\n1. **"Let\'s circle back on this"** — revisit later\n2. **"Moving forward"** — from now on\n3. **"Touch base"** — make brief contact\n4. **"On the same page"** — mutual understanding\n5. **"The ball is in your court"** — it\'s your decision now',
  'affect': 'Great vocabulary question!\n\n**Affect** (verb) = to influence something\n→ *The rain affected our plans.*\n\n**Effect** (noun) = the result of something\n→ *The effect of rain was a cancelled picnic.*\n\n💡 **Memory trick:** **A**ffect = **A**ction (verb), **E**ffect = **E**nd result (noun)',
  'perfect': 'The **Present Perfect** connects the past to now!\n\n**Formula:** have/has + past participle\n\n**Uses:**\n1. Experience: *I have visited London.*\n2. Recent past: *She has just finished.*\n3. With \'since/for\': *I have lived here for 3 years.*\n\n💡 **Contrast with Simple Past:** Simple Past = finished action, Present Perfect = action still relevant now.',
};

String getAIResponse(String input) {
  final lower = input.toLowerCase();
  if (lower.contains('resilient')) return aiResponses['resilient']!;
  if (lower.contains('grammar') || lower.contains('don\'t') || lower.contains('dont')) return aiResponses['grammar']!;
  if (lower.contains('business')) return aiResponses['business']!;
  if (lower.contains('affect') || lower.contains('effect')) return aiResponses['affect']!;
  if (lower.contains('perfect') || lower.contains('tense')) return aiResponses['perfect']!;
  return aiResponses['default']!;
}

String formatTime() {
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [
    Message(
      id: 0,
      role: 'ai',
      text: 'Hello! I\'m your AI English Tutor 🎓 Ask me anything about English — vocabulary, grammar, pronunciation, or practice sentences. I\'m here to help!',
      time: formatTime(),
    ),
  ];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showSuggestions = true;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _showSuggestions = false;
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch,
        role: 'user',
        text: text.trim(),
        time: formatTime(),
      ));
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    // Mock response delay
    Future.delayed(Duration(milliseconds: 1200 + Random().nextInt(600)), () {
      if (!mounted) return;
      setState(() {
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch,
          role: 'ai',
          text: getAIResponse(text),
          time: formatTime(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _messages.add(Message(
        id: 0,
        role: 'ai',
        text: 'Hello! I\'m your AI English Tutor 🎓 Ask me anything about English — vocabulary, grammar, pronunciation, or practice sentences. I\'m here to help!',
        time: formatTime(),
      ));
      _showSuggestions = true;
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4F46E5);
    final cardBorderColor = const Color(0xFF4F46E5).withOpacity(0.12);

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
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFEEF0FF),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI English Tutor',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF4F46E5)),
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + (_showSuggestions ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final msg = _messages[index];
                  final isAI = msg.role == 'ai';

                  return Align(
                    alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAI) ...[
                            Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor,
                              ),
                              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                            ),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isAI ? Colors.white : primaryColor,
                                    border: isAI ? Border.all(color: cardBorderColor) : null,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: isAI ? const Radius.circular(4) : const Radius.circular(18),
                                      bottomRight: isAI ? const Radius.circular(18) : const Radius.circular(4),
                                    ),
                                  ),
                                  child: isAI
                                      ? _buildFormattedAIText(msg.text)
                                      : Text(
                                          msg.text,
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Text(
                                    msg.time,
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFF6B6B8A),
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

                // If is typing
                if (_isTyping && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: cardBorderColor),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              children: List.generate(3, (i) {
                                return Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6B6B8A),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Suggestion chips
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Try asking:',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6B6B8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: SUGGESTED.map((s) {
                        return GestureDetector(
                          onTap: () => _sendMessage(s),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: cardBorderColor),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF0F0E2A),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Input box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: cardBorderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _inputController,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything in English...',
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget to render simple markdown like bold texts
  Widget _buildFormattedAIText(String text) {
    // Simple custom parser for **bold** text and newlines
    final parts = text.split(RegExp(r'(\*\*[^*]+\*\*)'));
    final textSpans = <TextSpan>[];

    for (var p in parts) {
      if (p.startsWith('**') && p.endsWith('**')) {
        textSpans.add(TextSpan(
          text: p.substring(2, p.length - 2),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F0E2A)),
        ));
      } else {
        textSpans.add(TextSpan(
          text: p,
          style: GoogleFonts.inter(color: const Color(0xFF0F0E2A)),
        ));
      }
    }

    return RichText(
      text: TextSpan(
        children: textSpans,
        style: const TextStyle(height: 1.5, fontSize: 14),
      ),
    );
  }
}
