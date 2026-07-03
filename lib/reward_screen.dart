import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardScreen extends StatelessWidget {
  const RewardScreen({super.key});

  // Fungsi untuk memetakan nama ikon dari Firestore ke IconData Flutter
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star;
      case 'discount':
        return Icons.local_offer;
      case 'med':
        return Icons.medical_services;
      default:
        return Icons.card_giftcard;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Tukar Poin Reward")),
      body: Column(
        children: [
          // Header Poin User
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              int poin =
                  (snapshot.data?.data() as Map<String, dynamic>)['poin'] ?? 0;
              return Container(
                padding: const EdgeInsets.all(20),
                color: Colors.redAccent,
                child: Center(
                    child: Text("Poin Anda: $poin",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold))),
              );
            },
          ),
          // List Katalog Reward
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reward_katalog')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                var rewards = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: rewards.length,
                  itemBuilder: (context, i) {
                    var data = rewards[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(_getIcon(data['icon_name'] ?? ''),
                            size: 40, color: Colors.redAccent),
                        title: Text(data['nama_reward']),
                        subtitle: Text("${data['biaya_poin']} Poin"),
                        trailing: ElevatedButton(
                          onPressed: () => _tukarReward(
                              context, userId!, data, rewards[i].id),
                          child: const Text("Tukar"),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tukarReward(BuildContext context, String userId,
      Map<String, dynamic> reward, String rewardId) async {
    // Logika penukaran (cek poin cukup atau tidak)
    // 1. Cek poin user
    // 2. Jika cukup, kurangi poin dan catat ke koleksi 'transaksi_poin'
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Berhasil ditukar!")));
  }
}
