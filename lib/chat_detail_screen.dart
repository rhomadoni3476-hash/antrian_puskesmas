import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userId;
  final String namaPasien;

  const ChatDetailScreen({
    super.key,
    required this.userId,
    required this.namaPasien,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    final unreadMessages = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.userId)
        .collection('messages')
        .where('senderId', isNotEqualTo: _currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadMessages.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.update(
          FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(widget.userId),
          {'unreadCount': 0});
      await batch.commit();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final msg = _controller.text.trim();
    _controller.clear();

    final batch = FirebaseFirestore.instance.batch();
    final messageRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(widget.userId)
        .collection('messages')
        .doc();

    final roomRef =
        FirebaseFirestore.instance.collection('chat_rooms').doc(widget.userId);

    batch.set(messageRef, {
      'senderId': _currentUserId,
      'text': msg,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    batch.set(
        roomRef,
        {
          'lastMessage': msg,
          'lastUpdated': FieldValue.serverTimestamp(),
          'namaPasien': widget.namaPasien,
        },
        SetOptions(merge: true));

    await batch.commit();

    // Auto scroll setelah kirim pesan
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(widget.namaPasien[0].toUpperCase(),
                  style: const TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.namaPasien,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Text("Online",
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.redAccent));
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == _currentUserId;

                    // Logika Group Date (disederhanakan)
                    bool showDate = false;
                    if (index == messages.length - 1) {
                      showDate = true;
                    } else {
                      final prevData =
                          messages[index + 1].data() as Map<String, dynamic>;
                      final prevDate =
                          (prevData['timestamp'] as Timestamp?)?.toDate();
                      final currDate =
                          (data['timestamp'] as Timestamp?)?.toDate();
                      if (prevDate != null && currDate != null) {
                        showDate = DateFormat('yyyyMMdd').format(prevDate) !=
                            DateFormat('yyyyMMdd').format(currDate);
                      }
                    }

                    return Column(
                      children: [
                        if (showDate && data['timestamp'] != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Chip(
                              label: Text(
                                  DateFormat('EEEE, dd MMMM yyyy').format(
                                      (data['timestamp'] as Timestamp)
                                          .toDate()),
                                  style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                        _buildMessageBubble(data, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.redAccent),
                onPressed: () {}),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Balas pesan...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              backgroundColor: Colors.redAccent,
              onPressed: _sendMessage,
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.redAccent : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: isMe ? null : Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(data['text'] ?? "",
                style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              data['timestamp'] != null
                  ? DateFormat('HH:mm')
                      .format((data['timestamp'] as Timestamp).toDate())
                  : "",
              style: TextStyle(
                  fontSize: 9,
                  color: isMe ? Colors.white70 : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
