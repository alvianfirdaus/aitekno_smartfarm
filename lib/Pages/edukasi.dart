import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:http/http.dart' as http;

class EdukasiScreen extends StatefulWidget {
  @override
  _EdukasiScreenState createState() => _EdukasiScreenState();
}

// Model sederhana untuk item video
class VideoItem {
  final String link;
  final String id;
  final String title;
  final String? author;

  VideoItem({
    required this.link,
    required this.id,
    required this.title,
    this.author,
  });

  String get thumbnail => 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

class _EdukasiScreenState extends State<EdukasiScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<VideoItem> videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  // Ambil judul via oEmbed (tanpa API key)
  Future<Map<String, String>?> _fetchOEmbed(String url) async {
    try {
      final uri =
          Uri.parse('https://www.youtube.com/oembed?url=$url&format=json');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final title = (data['title'] ?? '').toString();
        final author = (data['author_name'] ?? '').toString();
        return {'title': title, 'author': author};
      }
    } catch (_) {}
    return null;
  }

  Future<void> _loadVideos() async {
    _db.child("zedukasi/edukasi").onValue.listen((event) async {
      final val = event.snapshot.value;
      final List<String> links = [];

      if (val is Map) {
        final entries = val.entries.toList()
          ..sort((a, b) {
            final ak = int.tryParse(a.key.toString()) ?? 0;
            final bk = int.tryParse(b.key.toString()) ?? 0;
            return ak.compareTo(bk);
          });
        for (final e in entries) {
          final url = e.value?.toString() ?? "";
          if (url.isNotEmpty && YoutubePlayer.convertUrlToId(url) != null) {
            links.add(url);
          }
        }
      } else if (val is List) {
        for (final item in val) {
          final url = item?.toString() ?? "";
          if (url.isNotEmpty && YoutubePlayer.convertUrlToId(url) != null) {
            links.add(url);
          }
        }
      }

      if (!mounted) return;
      setState(() => _loading = true);

      // Ambil metadata judul+author untuk tiap link
      final List<VideoItem> built = [];
      for (final link in links) {
        final id = YoutubePlayer.convertUrlToId(link)!;
        String title = 'Video';
        String? author;

        final meta = await _fetchOEmbed(link);
        if (meta != null && meta['title']!.isNotEmpty) {
          title = meta['title']!;
          author = meta['author'];
        } else {
          title = 'Video ($id)'; // fallback
        }

        built.add(VideoItem(link: link, id: id, title: title, author: author));
      }

      if (!mounted) return;
      setState(() {
        videos = built;
        _loading = false;
      });
    });
  }

  void _showVideoDialog(String url) {
    final String? videoId = YoutubePlayer.convertUrlToId(url);

    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Link tidak valid")),
      );
      return;
    }

    final YoutubePlayerController ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: YoutubePlayer(
            controller: ytController,
            showVideoProgressIndicator: true,
          ),
        );
      },
    ).then((_) {
      ytController.pause();
      ytController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header background
          Container(
            height: 230,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/edukasi.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Box judul
          Positioned(
            top: 158,
            left: 90,
            right: 90,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.video_library, color: Colors.green[900]),
                  const SizedBox(width: 8),
                  Text(
                    'Video Terbaru', // ✅ ganti judul
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Konten utama
          Column(
            children: [
              const SizedBox(height: 230),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : videos.isNotEmpty
                        ? ListView.builder(
                            itemCount: videos.length,
                            itemBuilder: (context, index) {
                              final v = videos[index];
                              return EdukasiCard(
                                title: v.title,
                                author: v.author,
                                link: v.link,
                                thumbnail: v.thumbnail,
                                onTap: () => _showVideoDialog(v.link),
                              );
                            },
                          )
                        : const Center(
                            child: Text(
                              "Belum ada video edukasi.",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EdukasiCard extends StatelessWidget {
  final String title;
  final String? author;
  final String link;
  final String thumbnail;
  final VoidCallback onTap;

  const EdukasiCard({
    required this.title,
    required this.link,
    required this.thumbnail,
    required this.onTap,
    this.author,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vid = YoutubePlayer.convertUrlToId(link);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // Thumbnail kiri
            SizedBox(
              width: 130,
              height: 80,
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              (progress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Judul + info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    if (author != null && author!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      vid != null ? "ID: $vid" : link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
