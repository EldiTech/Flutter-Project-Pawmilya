import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../theme/pawmilya_palette.dart';

class ChatScreen extends StatefulWidget {
  final String adoptionId;
  final Map<String, dynamic> data;

  const ChatScreen({super.key, required this.adoptionId, required this.data});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_msgController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String messageText = _msgController.text.trim();
    final String senderName = user.uid == widget.data['shelterId'] ? (widget.data['shelterName'] ?? 'Shelter Partner') : (widget.data['adopterName'] ?? 'Adopter');

    FirebaseFirestore.instance
        .collection('adoptions')
        .doc(widget.adoptionId)
        .collection('messages')
        .add({
      'text': messageText,
      'senderId': user.uid,
      'senderName': senderName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final recipientId = user.uid == widget.data['shelterId'] 
        ? widget.data['adopterId'] 
        : widget.data['shelterId'];

    if (recipientId != null) {
      NotificationService().createNotification(
        title: 'New message from $senderName',
        message: messageText,
        recipientId: recipientId,
        type: 'chat',
      );
    }

    _msgController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final petName = widget.data['petName'] ?? 'Updates';
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? '';
    final isShelter = currentUserId == widget.data['shelterId'];
    final otherPartyName = isShelter ? (widget.data['adopterName'] ?? 'Adopter') : (widget.data['shelterName'] ?? 'Partner Shelter');

    return Scaffold(
      backgroundColor: PawmilyaPalette.creamBottom,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adoption: $petName', style: const TextStyle(color: PawmilyaPalette.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Chat with $otherPartyName', style: const TextStyle(color: PawmilyaPalette.textSecondary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: PawmilyaPalette.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('adoptions')
                  .doc(widget.adoptionId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: PawmilyaPalette.gold));
                }

                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('Say hello! Start the conversation.', style: TextStyle(color: PawmilyaPalette.textSecondary)));
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Auto scrolls to bottom
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUserId;
                    final text = msg['text'] ?? '';
                    final timestamp = msg['timestamp'];
                    final timeStr = timestamp != null 
                        ? DateFormat('hh:mm a').format((timestamp as Timestamp).toDate()) 
                        : 'Just now';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? PawmilyaPalette.gold : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  msg['senderName'] ?? otherPartyName,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              text,
                              style: TextStyle(
                                color: isMe ? Colors.white : PawmilyaPalette.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12).copyWith(bottom: 24), // account for safe area
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: PawmilyaPalette.creamBottom,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: PawmilyaPalette.gold,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}