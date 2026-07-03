// File: lib/empty_state_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const EmptyStateWidget(
      {super.key,
      required this.title,
      required this.message,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, size: 50, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}
