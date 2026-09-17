import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/anime_model.dart';
import '../models/episode_model.dart';
import '../services/episode_service.dart';

class AnimeDetailScreen extends StatefulWidget {
  final AnimeModel anime;

  const AnimeDetailScreen({super.key, required this.anime});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final EpisodeService _episodeService = EpisodeService();

  EpisodeModel? _selectedEpisode;
  VideoPlayerController? _videoController;

  bool _isLoadingVideo = false;

  String? _registeredViewId;

  final TextEditingController _commentController = TextEditingController();

  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _videoController?.dispose();
    _commentController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ============================================================
  // VIDEO
  // ============================================================

  bool _isDirectVideo(String url) {
    final lower = url.toLowerCase();

    return lower.contains('.mp4') ||
        lower.contains('.webm') ||
        lower.contains('.mov') ||
        lower.contains('.m4v') ||
        lower.contains('.ogg') ||
        lower.contains('.ogv');
  }

  bool _isYoutube(String url) {
    final lower = url.toLowerCase();

    return lower.contains('youtube.com') || lower.contains('youtu.be');
  }

  String _getYoutubeEmbedUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be')) {
        final videoId = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first
            : '';

        if (videoId.isNotEmpty) {
          return 'https://www.youtube.com/embed/$videoId';
        }
      }

      // youtube.com/watch?v=VIDEO_ID
      if (uri.queryParameters.containsKey('v')) {
        final videoId = uri.queryParameters['v'] ?? '';

        if (videoId.isNotEmpty) {
          return 'https://www.youtube.com/embed/$videoId';
        }
      }

      // youtube.com/embed/VIDEO_ID
      if (uri.pathSegments.contains('embed')) {
        return url;
      }

      // youtube.com/shorts/VIDEO_ID
      if (uri.pathSegments.contains('shorts')) {
        final index = uri.pathSegments.indexOf('shorts');

        if (index + 1 < uri.pathSegments.length) {
          final videoId = uri.pathSegments[index + 1];

          return 'https://www.youtube.com/embed/$videoId';
        }
      }
    } catch (_) {}

    return url;
  }

  bool _isIframeUrl(String url) {
    final lower = url.toLowerCase();

    return lower.contains('/embed/') ||
        lower.contains('player.') ||
        lower.contains('iframe') ||
        lower.contains('dailymotion.com') ||
        lower.contains('vimeo.com');
  }

  // ============================================================
  // AUTO SELECT EPISODE 1
  // ============================================================

  void _autoSelectFirstEpisode(List<EpisodeModel> episodes) {
    if (episodes.isEmpty) {
      return;
    }

    // ถ้าเลือกตอนอยู่แล้ว ไม่ต้องเลือกใหม่
    if (_selectedEpisode != null) {
      final exists = episodes.any(
        (episode) => episode.id == _selectedEpisode!.id,
      );

      if (exists) {
        return;
      }
    }

    // พยายามหา EP.1
    EpisodeModel firstEpisode;

    try {
      firstEpisode = episodes.firstWhere((episode) => episode.episode == 1);
    } catch (_) {
      // ถ้าไม่มี EP.1 ให้ใช้ตอนแรกแทน
      firstEpisode = episodes.first;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // ป้องกันการโหลดซ้ำ
      if (_selectedEpisode?.id == firstEpisode.id) {
        return;
      }

      _loadVideo(firstEpisode);
    });
  }

  Future<void> _loadVideo(EpisodeModel episode) async {
    final url = episode.videoUrl.trim();

    // หยุด controller เก่าก่อน
    await _videoController?.dispose();
    _videoController = null;

    if (!mounted) return;

    setState(() {
      _selectedEpisode = episode;
      _isLoadingVideo = url.isNotEmpty;
      _registeredViewId = null;
    });

    if (url.isEmpty) {
      return;
    }

    // ========================================================
    // MP4 / WEBM / MOV
    // ========================================================

    if (_isDirectVideo(url)) {
      try {
        final controller = VideoPlayerController.networkUrl(Uri.parse(url));

        await controller.initialize();

        controller.setLooping(false);

        if (!mounted) {
          await controller.dispose();
          return;
        }

        setState(() {
          _videoController = controller;
          _isLoadingVideo = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoadingVideo = false;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่สามารถเปิดวิดีโอได้\n$e')));
      }

      return;
    }

    // ========================================================
    // YOUTUBE / IFRAME / EXTERNAL
    // ========================================================

    if (!mounted) return;

    setState(() {
      _isLoadingVideo = false;
    });
  }

  Future<void> _openExternalVideo(String url) async {
    try {
      final uri = Uri.parse(url);

      await launchUrl(uri, webOnlyWindowName: '_blank');
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดลิงก์วิดีโอได้')),
      );
    }
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _commentsCollection {
    return FirebaseFirestore.instance
        .collection('anime')
        .doc(widget.anime.id)
        .collection('comments');
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();

    final name = _nameController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('กรุณาพิมพ์ความคิดเห็น')));

      return;
    }

    try {
      await _commentsCollection.add({
        'name': name.isEmpty ? 'ผู้ชม' : name,
        'text': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เพิ่มความคิดเห็นเรียบร้อยแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเพิ่มความคิดเห็นได้\n$e')),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'เมื่อสักครู่';
    }

    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year;

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  // ============================================================
  // BUILD VIDEO
  // ============================================================

  Widget _buildVideoPlayer(double width) {
    final episode = _selectedEpisode;

    if (episode == null) {
      return _buildVideoPlaceholder(message: 'กำลังเตรียมตอนแรก...');
    }

    final url = episode.videoUrl.trim();

    if (url.isEmpty) {
      return _buildVideoPlaceholder(
        message: 'EP.${episode.episode} ยังไม่มี Video URL',
      );
    }

    if (_isLoadingVideo) {
      return Container(
        width: double.infinity,
        height: _getPlayerHeight(width),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    // MP4
    if (_isDirectVideo(url)) {
      return _buildDirectVideo();
    }

    // YouTube
    if (_isYoutube(url)) {
      final embedUrl = _getYoutubeEmbedUrl(url);

      return _buildIframePlayer(embedUrl, width);
    }

    // Iframe
    if (_isIframeUrl(url)) {
      return _buildIframePlayer(url, width);
    }

    // External
    return _buildExternalVideo(url);
  }

  double _getPlayerHeight(double width) {
    final double height = width < 700 ? width * 9 / 16 : 600.0;

    return height;
  }

  Widget _buildVideoPlaceholder({String message = 'กำลังเตรียมวิดีโอ...'}) {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 80,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectVideo() {
    final controller = _videoController;

    if (controller == null || !controller.value.isInitialized) {
      return _buildVideoPlaceholder(message: 'กำลังเตรียมวิดีโอ...');
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(controller),
            _VideoControls(controller: controller),
          ],
        ),
      ),
    );
  }

  Widget _buildIframePlayer(String url, double width) {
    final double height = _getPlayerHeight(width);

    final String viewId =
        'anime-ruka-iframe-${widget.anime.id}-${_selectedEpisode?.id ?? 'none'}';

    // ลงทะเบียนเฉพาะ view ใหม่
    if (_registeredViewId != viewId) {
      _registeredViewId = viewId;

      ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
        final iframe = html.IFrameElement();

        iframe.src = url;

        iframe.style.border = '0';
        iframe.style.width = '100%';
        iframe.style.height = '100%';
        iframe.style.backgroundColor = 'black';

        iframe.setAttribute(
          'allow',
          'autoplay; fullscreen; picture-in-picture; encrypted-media',
        );

        iframe.setAttribute('allowfullscreen', 'true');

        iframe.setAttribute('frameborder', '0');

        return iframe;
      });
    }

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: HtmlElementView(viewType: viewId),
    );
  }

  Widget _buildExternalVideo(String url) {
    return Container(
      width: double.infinity,
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new, color: Colors.red, size: 65),
            const SizedBox(height: 20),
            const Text(
              'วิดีโอนี้อยู่บนเว็บไซต์ภายนอก',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                url,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () {
                _openExternalVideo(url);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('เปิดวิดีโอ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EPISODE LIST
  // ============================================================

  Widget _buildEpisodeList(List<EpisodeModel> episodes) {
    if (episodes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('ยังไม่มีตอน', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;

        if (constraints.maxWidth >= 1000) {
          crossAxisCount = 8;
        } else if (constraints.maxWidth >= 700) {
          crossAxisCount = 6;
        } else if (constraints.maxWidth >= 450) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final episode = episodes[index];

            final isSelected = _selectedEpisode?.id == episode.id;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _loadVideo(episode);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    'EP.${episode.episode}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 15 : 14,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ANIME INFO
  // ============================================================

  Widget _buildAnimeInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.anime.title,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _infoChip(Icons.category, widget.anime.category),
            _infoChip(Icons.language, widget.anime.type),
            _infoChip(Icons.star, widget.anime.rating.toString()),
            _infoChip(Icons.video_library, 'EP.${widget.anime.latestEpisode}'),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.anime.description.isEmpty
              ? 'ยังไม่มีรายละเอียดของเรื่องนี้'
              : widget.anime.description,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 15,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.red),
          const SizedBox(width: 6),
          Text(text.isEmpty ? '-' : text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Widget _buildComments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ความคิดเห็น',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        _buildCommentForm(),
        const SizedBox(height: 25),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _commentsCollection
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ไม่สามารถโหลดความคิดเห็นได้',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }

            final comments = snapshot.data?.docs ?? [];

            if (comments.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'ยังไม่มีความคิดเห็น',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = comments[index].data();

                final name = data['name']?.toString() ?? 'ผู้ชม';

                final text = data['text']?.toString() ?? '';

                final timestamp = data['createdAt'] as Timestamp?;

                return _buildCommentItem(name, text, timestamp);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อผู้ใช้',
              hintText: 'เช่น Sakda',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'ความคิดเห็น',
              hintText: 'เขียนความคิดเห็นเกี่ยวกับเรื่องนี้...',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 65),
                child: Icon(Icons.comment_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addComment,
              icon: const Icon(Icons.send),
              label: const Text('ส่งความคิดเห็น'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String name, String text, Timestamp? timestamp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.red,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      _formatDate(timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: TextStyle(color: Colors.grey.shade400, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'ANIME-RUKA',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<List<EpisodeModel>>(
        stream: _episodeService.getEpisodes(widget.anime.id),
        builder: (context, snapshot) {
          final episodes = snapshot.data ?? [];

          // ======================================================
          // เลือก EP.1 อัตโนมัติ
          // ======================================================

          if (episodes.isNotEmpty) {
            _autoSelectFirstEpisode(episodes);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;

              final bool isMobile = width < 700;

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 30,
                        vertical: 25,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // =================================================
                          // VIDEO PLAYER
                          // =================================================

                          _buildVideoPlayer(width),

                          const SizedBox(height: 25),

                          // =================================================
                          // ANIME INFORMATION
                          // =================================================
                          _buildAnimeInfo(),

                          const SizedBox(height: 35),

                          // =================================================
                          // EPISODES
                          // =================================================
                          const Text(
                            'ตอนทั้งหมด',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          _buildEpisodeList(episodes),

                          const SizedBox(height: 45),

                          // =================================================
                          // COMMENTS
                          // =================================================
                          _buildComments(),

                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================
// VIDEO CONTROLS
// ============================================================

class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(_videoListener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);

    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePlay() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    final hours = duration.inHours;

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;

    final double maxSeconds = value.duration.inSeconds.toDouble();

    final double currentSeconds = value.position.inSeconds.toDouble();

    final double sliderMax = maxSeconds > 0 ? maxSeconds : 1.0;

    final double sliderValue = currentSeconds.clamp(0.0, sliderMax).toDouble();

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _showControls = true;
        });
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showControls ? 1 : 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
            ),
          ),
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: sliderValue,
                max: sliderMax,
                onChanged: (newValue) {
                  widget.controller.seekTo(Duration(seconds: newValue.toInt()));
                },
                activeColor: Colors.red,
                inactiveColor: Colors.grey.shade700,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _togglePlay,
                    icon: Icon(
                      value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    },
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
