import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // To access isFirebaseInitialized

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

String formatTime() {
  final now = DateTime.now();
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

// TODO: Add your Gemini API key here.
const String GEMINI_API_KEY = 'GEMINI_API_KEY';

class ChatScreen extends StatefulWidget {
  final Map<String, String> user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [
    Message(
      id: 0,
      role: 'ai',
      text:
          'Hello! I\'m Bera, your AI English Tutor 🎓 Ask me anything about English — vocabulary, grammar, pronunciation, or practice sentences. I\'m here to help!',
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

  Future<void> _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // Capture history before adding current message (exclude the initial greeting)
    final historyList = _messages
        .where((m) => m.id != 0)
        .map((m) => {
              'role': m.role,
              'text': m.text,
            })
        .toList();

    setState(() {
      _showSuggestions = false;
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch,
        role: 'user',
        text: trimmedText,
        time: formatTime(),
      ));
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      // Map history to Gemini format: { role: "user" | "model", parts: [{ text: "..." }] }
      final List<Map<String, dynamic>> contents = [];
      for (final msg in historyList) {
        contents.add({
          'role': msg['role'] == 'ai' ? 'model' : 'user',
          'parts': [
            {'text': msg['text']}
          ]
        });
      }

      // Add current user message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': trimmedText}
        ]
      });

      const String backendUrl = 'https://english-ai-study-backend.onrender.com/api/chat';

      // Call local backend server
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': trimmedText,
          'history': historyList,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final reply = data['reply'] ?? 'No response from tutor.';
        setState(() {
          _messages.add(Message(
            id: DateTime.now().millisecondsSinceEpoch,
            role: 'ai',
            text: reply,
            time: formatTime(),
          ));
          _isTyping = false;
        });

        final uid = widget.user['uid'];
        if (isFirebaseInitialized && uid != null) {
          try {
            await FirebaseFirestore.instance.collection('chat_history').add({
              'uid': uid,
              'question': trimmedText,
              'answer': reply,
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (e) { debugPrint('Error saving chat history to Firestore: $e'); }
        }
      } else {
        setState(() {
          _messages.add(Message(
            id: DateTime.now().millisecondsSinceEpoch,
            role: 'ai',
            text:
                'Sorry, I couldn\'t connect to the AI service. Please check your API key.',
            time: formatTime(),
          ));
          _isTyping = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch,
          role: 'ai',
          text: 'Connection error. Please check your internet connection.',
          time: formatTime(),
        ));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _messages.add(Message(
        id: 0,
        role: 'ai',
        text:
            'Hello! I\'m Bera, your AI English Tutor 🎓 Ask me anything about English — vocabulary, grammar, pronunciation, or practice sentences. I\'m here to help!',
        time: formatTime(),
      ));
      _showSuggestions = true;
      _isTyping = false;
    });
  }

  void _clickHelp() {
    setState(() {
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch,
        role: 'user',
        text: '/help',
        time: formatTime(),
      ));
      
      _messages.add(Message(
        id: DateTime.now().millisecondsSinceEpoch + 1,
        role: 'ai',
        text: 'Hello! I\'m Bera, your AI English Tutor 🎓 Ask me anything about English — vocabulary, grammar, pronunciation, or practice sentences. I\'m here to help!',
        time: formatTime(),
      ));
      
      _showSuggestions = true;
    });
    _scrollToBottom();
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
              child: const Icon(Icons.auto_awesome,
                  color: Color(0xFF4F46E5), size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Tutor Bera',
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
              itemCount: _messages.length +
                  (_isTyping ? 1 : 0) +
                  (_showSuggestions ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final msg = _messages[index];
                  final isAI = msg.role == 'ai';

                  return Align(
                    alignment:
                        isAI ? Alignment.centerLeft : Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        mainAxisAlignment: isAI
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
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
                              child: const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 14),
                            ),
                          ],
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isAI
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isAI ? Colors.white : primaryColor,
                                    border: isAI
                                        ? Border.all(color: cardBorderColor)
                                        : null,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: isAI
                                          ? const Radius.circular(4)
                                          : const Radius.circular(18),
                                      bottomRight: isAI
                                          ? const Radius.circular(18)
                                          : const Radius.circular(4),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
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
                            child: const Icon(Icons.auto_awesome,
                                color: Colors.white, size: 14),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
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
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: cardBorderColor),
              ),
            ),
            child: Row(
              children: [
                // /help Button
                GestureDetector(
                  onTap: _clickHelp,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withOpacity(0.24)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '/help',
                      style: GoogleFonts.inter(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Input Field Container enclosing both TextField and Send Button
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F1FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.16),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.only(left: 14, right: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            onSubmitted: _sendMessage,
                            decoration: const InputDecoration(
                              hintText: 'Ask me anything in English...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            style: GoogleFonts.inter(fontSize: 13.5),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Send Button INSIDE the field
                        GestureDetector(
                          onTap: () => _sendMessage(_inputController.text),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child:
                                const Icon(Icons.send, color: Colors.white, size: 14),
                          ),
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
    );
  }

  // Helper widget to render simple markdown like bold texts
  Widget _buildFormattedAIText(String text) {
    final textSpans = <TextSpan>[];
    final regex = RegExp(r'\*\*([^*]+)\*\*');

    int lastIndex = 0;
    for (final Match match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        textSpans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: GoogleFonts.inter(color: const Color(0xFF0F0E2A)),
        ));
      }

      // Add the bold matched text
      textSpans.add(TextSpan(
        text: match.group(1),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F0E2A),
        ),
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      textSpans.add(TextSpan(
        text: text.substring(lastIndex),
        style: GoogleFonts.inter(color: const Color(0xFF0F0E2A)),
      ));
    }

    return RichText(
      text: TextSpan(
        children: textSpans,
        style: const TextStyle(height: 1.5, fontSize: 14),
      ),
    );
  }
}
