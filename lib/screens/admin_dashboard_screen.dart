import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/anime_model.dart';
import '../models/episode_model.dart';
import '../services/anime_service.dart';
import '../services/episode_service.dart';
import 'admin_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AnimeService _animeService = AnimeService();
  final EpisodeService _episodeService = EpisodeService();

  int _selectedMenu = 0;

  final List<String> _menus = ['Dashboard', 'Anime', 'Episodes', 'Comments'];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text(
          'ANIME-RUKA ADMIN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: const Color(0xFF111111),
      child: Column(
        children: [
          const SizedBox(height: 25),

          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.red,
            child: Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'ADMIN PANEL',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: ListView.builder(
              itemCount: _menus.length,
              itemBuilder: (context, index) {
                final selected = _selectedMenu == index;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? Colors.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    leading: Icon(_getMenuIcon(index), color: Colors.white),
                    title: Text(
                      _menus[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedMenu = index;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              'ANIME-RUKA v1.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMenuIcon(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard;
      case 1:
        return Icons.movie;
      case 2:
        return Icons.video_library;
      case 3:
        return Icons.comment;
      default:
        return Icons.menu;
    }
  }

  Widget _buildContent() {
    switch (_selectedMenu) {
      case 0:
        return _buildDashboard();

      case 1:
        return _buildAnimeManagement();

      case 2:
        return _buildEpisodeManagement();

      case 3:
        return _buildCommentManagement();

      default:
        return _buildDashboard();
    }
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('anime').snapshots(),
      builder: (context, animeSnapshot) {
        if (animeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final animeDocs = animeSnapshot.data?.docs ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'จัดการเว็บไซต์ ANIME-RUKA',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 30),

              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  int columns = 4;

                  if (width < 900) {
                    columns = 2;
                  }

                  if (width < 550) {
                    columns = 1;
                  }

                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 2.4,
                    children: [
                      _statCard(
                        'Anime',
                        animeDocs.length.toString(),
                        Icons.movie,
                      ),
                      _statCard('Episodes', 'ดูข้อมูล', Icons.video_library),
                      _statCard('Comments', 'ดูข้อมูล', Icons.comment),
                      _statCard('Admin', 'Online', Icons.admin_panel_settings),
                    ],
                  );
                },
              ),

              const SizedBox(height: 35),

              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMenu = 1;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('เพิ่ม Anime'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMenu = 2;
                            });
                          },
                          icon: const Icon(Icons.video_library),
                          label: const Text('จัดการ Episode'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedMenu = 3;
                            });
                          },
                          icon: const Icon(Icons.comment),
                          label: const Text('จัดการ Comments'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANIME MANAGEMENT
  // ============================================================

  Widget _buildAnimeManagement() {
    return StreamBuilder<List<AnimeModel>>(
      stream: _animeService.getAnimeStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final animeList = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'จัดการ Anime',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAnimeDialog();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่ม Anime'),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Expanded(
                child: animeList.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มีข้อมูล Anime',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: animeList.length,
                        itemBuilder: (context, index) {
                          final anime = animeList[index];

                          return _animeAdminCard(anime);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _animeAdminCard(AnimeModel anime) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: anime.imageUrl.isNotEmpty
                ? Image.network(
                    anime.imageUrl,
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _posterPlaceholder();
                    },
                  )
                : _posterPlaceholder(),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  anime.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(anime.category, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 5),

                Text(
                  'EP ล่าสุด: ${anime.latestEpisode}  |  Rating: ${anime.rating}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'แก้ไข',
            onPressed: () {
              _showAnimeDialog(anime: anime);
            },
            icon: const Icon(Icons.edit, color: Colors.blue),
          ),

          IconButton(
            tooltip: 'ลบ',
            onPressed: () {
              _confirmDeleteAnime(anime);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 80,
      height: 110,
      color: const Color(0xFF222222),
      child: const Icon(Icons.movie, color: Colors.grey, size: 35),
    );
  }

  Future<void> _showAnimeDialog({AnimeModel? anime}) async {
    final titleController = TextEditingController(text: anime?.title ?? '');

    final categoryController = TextEditingController(
      text: anime?.category ?? '',
    );

    final imageController = TextEditingController(text: anime?.imageUrl ?? '');

    final descriptionController = TextEditingController(
      text: anime?.description ?? '',
    );

    final typeController = TextEditingController(text: anime?.type ?? 'ซับไทย');

    final ratingController = TextEditingController(
      text: anime?.rating.toString() ?? '0',
    );

    final episodeController = TextEditingController(
      text: anime?.latestEpisode.toString() ?? '1',
    );

    bool isFeatured = anime?.isFeatured ?? false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF181818),
              title: Text(anime == null ? 'เพิ่ม Anime' : 'แก้ไข Anime'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อ Anime',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'หมวดหมู่',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'คำอธิบาย',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: typeController,
                        decoration: const InputDecoration(labelText: 'ประเภท'),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: ratingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Rating'),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: episodeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Episode ล่าสุด',
                        ),
                      ),

                      const SizedBox(height: 10),

                      SwitchListTile(
                        value: isFeatured,
                        title: const Text('Featured Anime'),
                        onChanged: (value) {
                          setDialogState(() {
                            isFeatured = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();

                    if (title.isEmpty) {
                      return;
                    }

                    final data = {
                      'title': title,
                      'category': categoryController.text.trim(),
                      'imageUrl': imageController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'type': typeController.text.trim(),
                      'rating': double.tryParse(ratingController.text) ?? 0.0,
                      'latestEpisode':
                          int.tryParse(episodeController.text) ?? 1,
                      'isFeatured': isFeatured,
                      'isFavorite': anime?.isFavorite ?? false,
                    };

                    if (anime == null) {
                      await _animeService.addAnime(data);
                    } else {
                      await _animeService.updateAnime(anime.id, data);
                    }

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    _showMessage(
                      anime == null
                          ? 'เพิ่ม Anime สำเร็จ'
                          : 'แก้ไข Anime สำเร็จ',
                    );
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    categoryController.dispose();
    imageController.dispose();
    descriptionController.dispose();
    typeController.dispose();
    ratingController.dispose();
    episodeController.dispose();
  }

  Future<void> _confirmDeleteAnime(AnimeModel anime) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('ยืนยันการลบ'),
          content: Text('ต้องการลบ "${anime.title}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await _deleteAnimeCompletely(anime.id);

    _showMessage('ลบ Anime สำเร็จ');
  }

  Future<void> _deleteAnimeCompletely(String animeId) async {
    final animeRef = FirebaseFirestore.instance
        .collection('anime')
        .doc(animeId);

    final episodes = await animeRef.collection('episodes').get();

    final comments = await animeRef.collection('comments').get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in episodes.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in comments.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(animeRef);

    await batch.commit();
  }

  // ============================================================
  // EPISODE MANAGEMENT
  // ============================================================

  Widget _buildEpisodeManagement() {
    return StreamBuilder<List<AnimeModel>>(
      stream: _animeService.getAnimeStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final animeList = snapshot.data ?? [];

        if (animeList.isEmpty) {
          return const Center(
            child: Text(
              'กรุณาเพิ่ม Anime ก่อน',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          );
        }

        return DefaultTabController(
          length: animeList.length,
          child: Column(
            children: [
              Container(
                color: const Color(0xFF111111),
                child: TabBar(
                  isScrollable: true,
                  tabs: animeList.map((anime) {
                    return Tab(text: anime.title);
                  }).toList(),
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: animeList.map((anime) {
                    return _episodeList(anime);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _episodeList(AnimeModel anime) {
    return StreamBuilder<List<EpisodeModel>>(
      stream: _episodeService.getEpisodes(anime.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final episodes = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Episodes - ${anime.title}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showEpisodeDialog(anime);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่ม Episode'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: episodes.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มี Episode',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: episodes.length,
                        itemBuilder: (context, index) {
                          final episode = episodes[index];

                          return _episodeCard(anime, episode);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _episodeCard(AnimeModel anime, EpisodeModel episode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'EP\n${episode.episode}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  episode.title.isEmpty
                      ? 'Episode ${episode.episode}'
                      : episode.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  episode.videoUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'แก้ไข',
            onPressed: () {
              _showEpisodeDialog(anime, episode: episode);
            },
            icon: const Icon(Icons.edit, color: Colors.blue),
          ),

          IconButton(
            tooltip: 'ลบ',
            onPressed: () {
              _deleteEpisode(anime, episode);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _showEpisodeDialog(
    AnimeModel anime, {
    EpisodeModel? episode,
  }) async {
    final numberController = TextEditingController(
      text: episode?.episode.toString() ?? '',
    );

    final titleController = TextEditingController(text: episode?.title ?? '');

    final videoController = TextEditingController(
      text: episode?.videoUrl ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: Text(episode == null ? 'เพิ่ม Episode' : 'แก้ไข Episode'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'หมายเลข Episode',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ Episode',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: videoController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Video URL',
                      hintText: 'https://example.com/video.mp4',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final number = int.tryParse(numberController.text.trim());

                if (number == null) {
                  return;
                }

                final data = {
                  'episode': number,
                  'title': titleController.text.trim(),
                  'videoUrl': videoController.text.trim(),
                };

                if (episode == null) {
                  await _episodeService.addEpisode(anime.id, data);
                } else {
                  await _episodeService.updateEpisode(
                    anime.id,
                    episode.id,
                    data,
                  );
                }

                await _updateLatestEpisode(anime.id);

                if (!mounted) return;

                Navigator.pop(dialogContext);

                _showMessage(
                  episode == null
                      ? 'เพิ่ม Episode สำเร็จ'
                      : 'แก้ไข Episode สำเร็จ',
                );
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );

    numberController.dispose();
    titleController.dispose();
    videoController.dispose();
  }

  Future<void> _deleteEpisode(AnimeModel anime, EpisodeModel episode) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('ยืนยันการลบ Episode'),
          content: Text('ต้องการลบ Episode ${episode.episode} หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await _episodeService.deleteEpisode(anime.id, episode.id);

    await _updateLatestEpisode(anime.id);

    _showMessage('ลบ Episode สำเร็จ');
  }

  Future<void> _updateLatestEpisode(String animeId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('anime')
        .doc(animeId)
        .collection('episodes')
        .get();

    int latest = 0;

    for (final doc in snapshot.docs) {
      final value = doc.data()['episode'];

      final number = value is int
          ? value
          : int.tryParse(value?.toString() ?? '') ?? 0;

      if (number > latest) {
        latest = number;
      }
    }

    await FirebaseFirestore.instance.collection('anime').doc(animeId).update({
      'latestEpisode': latest,
    });
  }

  // ============================================================
  // COMMENT MANAGEMENT
  // ============================================================

  Widget _buildCommentManagement() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Text(
                'ไม่สามารถโหลด Comments ได้\n\n'
                '${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data?.docs ?? [];

        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'จัดการ Comments',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'จำนวน Comments: ${comments.length}',
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: comments.isEmpty
                    ? const Center(
                        child: Text(
                          'ยังไม่มี Comments',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return _commentCard(comments[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _commentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final text = data['text']?.toString() ?? '';

    final username = data['username']?.toString() ?? 'ผู้ใช้';

    final createdAt = data['createdAt'];

    String dateText = '';

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();

      dateText =
          '${date.day}/${date.month}/${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    final parentAnime = doc.reference.parent.parent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.red,
            child: Icon(Icons.person, color: Colors.white),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 6),

                Text(text, style: const TextStyle(fontSize: 15)),

                if (dateText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    dateText,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],

                if (parentAnime != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Anime ID: ${parentAnime.id}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            tooltip: 'ลบ Comment',
            onPressed: () {
              _deleteComment(doc);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('ลบ Comment'),
          content: const Text('ต้องการลบ Comment นี้หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    await doc.reference.delete();

    _showMessage('ลบ Comment สำเร็จ');
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
