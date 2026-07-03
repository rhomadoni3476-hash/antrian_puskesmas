import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TeleKonsultasiScreen extends StatefulWidget {
  const TeleKonsultasiScreen({super.key});

  @override
  State<TeleKonsultasiScreen> createState() => _TeleKonsultasiScreenState();
}

class _TeleKonsultasiScreenState extends State<TeleKonsultasiScreen> {
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  String _namaPasien = "Pasien";
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => _namaPasien = doc.data()?['nama'] ?? "Pasien");
      }
    }
  }

  Future<void> _kirimPesanFirestore({String? text, String? imageUrl}) async {
    final user = FirebaseAuth.instance.currentUser!;
    final batch = FirebaseFirestore.instance.batch();

    final messageRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(user.uid)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': user.uid,
      'text': text ?? "[FOTO_KONSULTASI]",
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    final roomRef =
        FirebaseFirestore.instance.collection('chat_rooms').doc(user.uid);
    batch.set(
        roomRef,
        {
          'namaPasien': _namaPasien,
          'lastMessage': text ?? "Mengirim foto",
          'lastUpdated': FieldValue.serverTimestamp(),
          'unreadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() => _isSending = true);
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref =
          FirebaseStorage.instance.ref().child('chat_images/$fileName');
      await ref.putFile(File(image.path));
      String downloadUrl = await ref.getDownloadURL();
      await _kirimPesanFirestore(imageUrl: downloadUrl);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal upload: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _kirimPesan() async {
    if (_chatController.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    try {
      await _kirimPesanFirestore(text: _chatController.text.trim());
      _chatController.clear();
      _focusNode.unfocus();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      floatingActionButton: isKeyboardVisible
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton(
                heroTag: "darurat",
                backgroundColor: Colors.white,
                elevation: 8,
                onPressed: () {},
                child: const Icon(Icons.emergency,
                    color: Colors.redAccent, size: 28),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      body: Container(
        decoration: const BoxDecoration(
            gradient:
                LinearGradient(colors: [Color(0xFFFDFDFD), Color(0xFFF2F4F7)])),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: () => Navigator.pop(context)),
                    Text("Tele-Konsultasi",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(currentUser?.uid)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.redAccent));
                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) => _buildChatBubble(
                          docs[index].data() as Map<String, dynamic>),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.camera_alt_rounded,
                              color: Colors.redAccent),
                          onPressed: _pickAndUploadImage),
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: "Sampaikan keluhan...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _isSending
                          ? const CircularProgressIndicator()
                          : Container(
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent),
                              child: IconButton(
                                  icon: const Icon(Icons.send_rounded,
                                      color: Colors.white),
                                  onPressed: _kirimPesan),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> data) {
    bool isMe = data['senderId'] == FirebaseAuth.instance.currentUser?.uid;
    String? imageUrl = data['imageUrl'];
    String text = data['text'] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? Colors.redAccent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 150,
                      width: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          width: 200,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              if (text.isNotEmpty && text != "[FOTO_KONSULTASI]")
                Text(text,
                    style: GoogleFonts.poppins(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
