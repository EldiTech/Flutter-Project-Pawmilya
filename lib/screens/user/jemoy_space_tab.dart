import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../theme/pawmilya_palette.dart';

class JemoySpaceTab extends StatefulWidget {
  const JemoySpaceTab({super.key});

  @override
  State<JemoySpaceTab> createState() => _JemoySpaceTabState();
}

class _JemoySpaceTabState extends State<JemoySpaceTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Provide via: flutter run/build --dart-define=GEMINI_API_KEY=...
  final String _geminiApiKey = const String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    if (_userId == null) return;
    final chatRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('jemoy_chats');
    final snapshot = await chatRef.limit(1).get();
    
    if (snapshot.docs.isEmpty) {
      await chatRef.add({
        'text': "Woof! I'm Jemoy, your friendly AI companion. How can I help you and your furry friends today?",
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _userId == null) return;

    final chatRef = FirebaseFirestore.instance.collection('users').doc(_userId).collection('jemoy_chats');

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();
    
    // Save user message to Firestore
    await chatRef.add({
      'text': text,
      'isUser': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();

    try {
      final reply = await _getGeminiResponse(text);
      
      // Save AI response to Firestore
      await chatRef.add({
        'text': reply,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        setState(() { _isLoading = false; });
        _scrollToBottom();
      }
    } catch (e) {
      await chatRef.add({
        'text': "Arf! Something went wrong accessing my brain. Please try again! ($e)",
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        setState(() { _isLoading = false; });
        _scrollToBottom();
      }
    }
  }

  Future<String> _getGeminiResponse(String prompt) async {
    if (_geminiApiKey.isEmpty) {
      return "Missing GEMINI_API_KEY. Run with --dart-define=GEMINI_API_KEY=...";
    }

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_geminiApiKey');
    
    // Pass recent context as part of the prompt for a basic conversational feel
    String conversationContext = "You are Jemoy, a friendly, helpful, and slightly playful AI assistant dog for a pet adoption and reporting app called Pawmilya. Respond warmly and concisely.\n\n";
    conversationContext += "User: $prompt";

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [{"text": conversationContext}]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
        }
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      return text.trim();
    } else {
      debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to connect to Gemini (Status: ${response.statusCode})');
    }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFF6E7),
                    border: Border.all(
                      color: const Color(0xFFD28734).withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD28734).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.15,
                      child: FractionalTranslation(
                        translation: const Offset(0, 0.02),
                        child: Image.asset(
                          'assets/images/app_logo_trans.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => const Icon(
                            Icons.pets_rounded,
                            color: Color(0xFFB97331),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jemoy',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B4527),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online - AI Assistant',
                          style: TextStyle(
                            fontSize: 13,
                            color: PawmilyaPalette.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: _userId == null 
              ? const Center(child: Text("Please log in to chat with Jemoy."))
              : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_userId)
                    .collection('jemoy_chats')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink(); // Waiting for the initial message
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final message = Message(
                        text: data['text'] ?? '',
                        isUser: data['isUser'] ?? false,
                      );
                      return _buildMessageBubble(message);
                    },
                  );
                },
              ),
          ),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    ClipOval(
                      child: Container(
                        color: const Color(0xFFFFF6E7),
                        width: 22,
                        height: 22,
                        child: Transform.scale(
                          scale: 1.15,
                          child: FractionalTranslation(
                            translation: const Offset(0, 0.02),
                            child: Image.asset(
                              'assets/images/app_logo_trans.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Jemoy is thinking...',
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Ask Jemoy anything...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey : PawmilyaPalette.gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: message.isUser ? PawmilyaPalette.gold : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(message.isUser ? 20 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : PawmilyaPalette.textPrimary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}