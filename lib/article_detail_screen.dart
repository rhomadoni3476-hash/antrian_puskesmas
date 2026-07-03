import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String content;
  final Color themeColor;

  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.themeColor,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  void _updateProgress() {
    if (_scrollController.hasClients) {
      setState(() {
        _scrollProgress = _scrollController.position.pixels /
            _scrollController.position.maxScrollExtent;
      });
    }
  }

  // Helper untuk menghitung estimasi durasi baca (rata-rata 200 kata per menit)
  String _getReadingTime(String text) {
    int wordCount = text.split(RegExp(r'\s+')).length;
    int minutes = (wordCount / 200).ceil();
    return "$minutes min read";
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: widget.themeColor,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.themeColor,
                          widget.themeColor.withOpacity(0.7)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.health_and_safety_rounded,
                          size: 100, color: Colors.white.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Kategori & Waktu Baca
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                                color: widget.themeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(widget.subtitle,
                                style: GoogleFonts.poppins(
                                    color: widget.themeColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(_getReadingTime(widget.content),
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(widget.title,
                          style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.2)),

                      const SizedBox(height: 20),
                      // Author Info
                      Row(
                        children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor: widget.themeColor,
                              child: const Icon(Icons.local_hospital,
                                  size: 16, color: Colors.white)),
                          const SizedBox(width: 10),
                          Text("Puskesmas Digital",
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                      const SizedBox(height: 24),

                      Text(widget.content,
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              height: 1.8,
                              color: Colors.grey.shade800)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Reading Progress Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _scrollProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(widget.themeColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berbagi artikel ke teman..."))),
        backgroundColor: widget.themeColor,
        child: const Icon(Icons.share_rounded, color: Colors.white),
      ),
    );
  }
}
