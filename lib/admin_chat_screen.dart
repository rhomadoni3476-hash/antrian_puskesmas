import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_detail_screen.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pesan Pasien"),
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
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white24,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                hintStyle: const TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          var rooms = snapshot.data!.docs;

          // Filter berdasarkan pencarian
          if (_searchQuery.isNotEmpty) {
            rooms = rooms.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['namaPasien'] as String)
                  .toLowerCase()
                  .contains(_searchQuery);
            }).toList();
          }

          if (rooms.isEmpty) {
            return const Center(child: Text("Tidak ada pesan ditemukan"));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>;
              final String userId = rooms[index].id;
              final int unreadCount = data['unreadCount'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: unreadCount > 0 ? 4 : 1,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: unreadCount > 0
                        ? Colors.redAccent
                        : Colors.grey.shade300,
                    child: Text(
                      data['namaPasien']?[0].toUpperCase() ?? "?",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    data['namaPasien'] ?? "Pasien",
                    style: TextStyle(
                        fontWeight: unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal),
                  ),
                  subtitle: Text(
                    data['lastMessage'] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              color: Colors.redAccent, shape: BoxShape.circle),
                          child: Text("$unreadCount",
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        )
                      else
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          userId: userId,
                          namaPasien: data['namaPasien'] ?? "Pasien",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
