import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void tampilkanDialogRating(BuildContext context, String idAntrian) {
  double ratingInput = 5.0;
  final TextEditingController komentarController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false, // Mencegah dialog tertutup jika klik di luar
    builder: (context) => AlertDialog(
      title: const Text("Beri Penilaian"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Bagaimana pelayanan Puskesmas hari ini?"),
          const SizedBox(height: 15),
          RatingBar.builder(
            initialRating: 5,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemBuilder: (context, _) =>
                const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) => ratingInput = rating,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: komentarController,
            decoration: const InputDecoration(
              hintText: "Tulis saran Anda...",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal")),
        ElevatedButton(
          onPressed: () async {
            try {
              final user = FirebaseAuth.instance.currentUser;

              // 1. Tambahkan ke koleksi 'reviews'
              await FirebaseFirestore.instance.collection('reviews').add({
                'id_antrian': idAntrian,
                'uid_pasien': user?.uid ?? 'anonymous',
                'rating': ratingInput,
                'komentar': komentarController.text,
                'timestamp': FieldValue.serverTimestamp(),
              });

              // 2. KRUSIAL: Update status antrian agar dialog tidak muncul lagi
              await FirebaseFirestore.instance
                  .collection('antrian')
                  .doc(idAntrian)
                  .update({
                'sudah_dirating': true,
              });

              // 3. Gunakan pengecekan mounted untuk keamanan
              if (!context.mounted) return;
              Navigator.pop(context);

              // 4. Feedback sukses
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Terima kasih atas masukan Anda!")),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Gagal mengirim: $e")),
              );
            }
          },
          child: const Text("Kirim"),
        ),
      ],
    ),
  );
}
