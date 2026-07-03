import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonAntrian extends StatelessWidget {
  const SkeletonAntrian({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.white),
        title: Container(height: 15, color: Colors.white),
        subtitle: Container(height: 10, color: Colors.white),
      ),
    );
  }
}
