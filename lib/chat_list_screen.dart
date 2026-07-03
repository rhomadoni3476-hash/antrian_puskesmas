import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Konsultasi"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Cari nama pasien...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .orderBy('lastUpdated', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.redAccent));
          }

          // Filter data berdasarkan pencarian
          final rooms = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['namaPasien'] ?? "")
                .toString()
                .toLowerCase()
                .contains(_searchQuery);
          }).toList();

          if (rooms.isEmpty) {
            return const Center(child: Text("Tidak ada percakapan ditemukan."));
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (ctx, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>;
              final userId = rooms[index].id;
              final namaPasien = data['namaPasien'] ?? "Pasien";
              final lastMsg = data['lastMessage'] ?? "";
              final lastTime = data['lastUpdated'] as Timestamp?;
              final int unreadCount = data['unreadCount'] ?? 0;

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.red.shade100,
                      child: Text(namaPasien[0].toUpperCase(),
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: Text("$unreadCount",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
                title: Text(namaPasien,
                    style: TextStyle(
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal)),
                subtitle:
                    Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lastTime != null
                          ? DateFormat('HH:mm').format(lastTime.toDate())
                          : "",
                      style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0 ? Colors.red : Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  // Reset unreadCount saat chat dibuka
                  FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(userId)
                      .update({'unreadCount': 0});
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                          userId: userId, namaPasien: namaPasien),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
