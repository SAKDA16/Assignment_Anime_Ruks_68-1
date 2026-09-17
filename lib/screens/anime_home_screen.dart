import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/anime_model.dart';
import 'anime_detail_screen.dart';

class AnimeHomeScreen extends StatefulWidget {
  const AnimeHomeScreen({super.key});

  @override
  State<AnimeHomeScreen> createState() => _AnimeHomeScreenState();
}

class _AnimeHomeScreenState extends State<AnimeHomeScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String selectedCategory = 'ทั้งหมด';

  final List<String> categories = [
    'ทั้งหมด',
    'Action',
    'Adventure',
    'Comedy',
    'Romance',
    'Fantasy',
    'Drama',
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // เปิดหน้า Anime Detail
  // =========================================================

  void _openAnimeDetail(String id, Map<String, dynamic> data) {
    final anime = AnimeModel.fromMap(id, data);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AnimeDetailScreen(anime: anime);
        },
      ),
    );
  }

  // =========================================================
  // ค้นหา
  // =========================================================

  void _searchAnime(String value) {
    setState(() {
      searchText = value.toLowerCase();
    });
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('anime')
            .orderBy('title')
            .snapshots(),

        builder: (context, snapshot) {
          // กำลังโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'เกิดข้อผิดพลาด\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          // ไม่มีข้อมูล
          if (documents.isEmpty) {
            return _buildEmptyDatabase();
          }

          // กรองข้อมูล
          final filteredAnime = documents.where((doc) {
            final data = doc.data();

            final title = data['title']?.toString().toLowerCase() ?? '';

            final category = data['category']?.toString() ?? '';

            final matchSearch = title.contains(searchText);

            final matchCategory =
                selectedCategory == 'ทั้งหมด' || category == selectedCategory;

            return matchSearch && matchCategory;
          }).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // HERO
                // =================================================

                _buildHero(),

                const SizedBox(height: 35),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =================================================
                      // CATEGORY
                      // =================================================

                      const Text(
                        'หมวดหมู่',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildCategories(),

                      const SizedBox(height: 35),

                      // =================================================
                      // TITLE
                      // =================================================
                      Row(
                        children: [
                          const Text(
                            'อนิเมะทั้งหมด',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            '${filteredAnime.length} เรื่อง',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // =================================================
                      // GRID
                      // =================================================
                      if (filteredAnime.isEmpty)
                        _buildNoSearchResult()
                      else
                        _buildAnimeGrid(filteredAnime),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // APP BAR
  // =========================================================

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF080808),

      elevation: 0,

      title: Row(
        children: const [
          Text(
            'ANIME',
            style: TextStyle(
              color: Colors.red,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '-RUKA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),

      actions: [
        SizedBox(
          width: 270,

          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),

            child: TextField(
              controller: searchController,

              onChanged: _searchAnime,

              decoration: InputDecoration(
                hintText: 'ค้นหาอนิเมะ...',

                prefixIcon: const Icon(Icons.search, color: Colors.grey),

                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            searchText = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        IconButton(
          tooltip: 'หน้าแรก',
          onPressed: () {},
          icon: const Icon(Icons.home),
        ),

        const SizedBox(width: 10),
      ],
    );
  }

  // =========================================================
  // HERO
  // =========================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      height: 430,

      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF250000), Color(0xFF080808)],
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 60),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(5),
              ),

              child: const Text(
                'ANIME-RUKA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'ดูอนิเมะออนไลน์',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 10),

            const Text(
              'รวมอนิเมะที่คุณชื่นชอบ\n'
              'พร้อมระบบค้นหาและเลือกตอน',
              style: TextStyle(color: Colors.grey, fontSize: 18, height: 1.6),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {},

              icon: const Icon(Icons.play_arrow),

              label: const Text('ดูอนิเมะ'),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // CATEGORY
  // =========================================================

  Widget _buildCategories() {
    return SizedBox(
      height: 45,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        itemCount: categories.length,

        separatorBuilder: (context, index) {
          return const SizedBox(width: 10);
        },

        itemBuilder: (context, index) {
          final category = categories[index];

          final selected = selectedCategory == category;

          return ChoiceChip(
            label: Text(category),

            selected: selected,

            selectedColor: Colors.red,

            backgroundColor: const Color(0xFF1A1A1A),

            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.grey,

              fontWeight: FontWeight.bold,
            ),

            onSelected: (_) {
              setState(() {
                selectedCategory = category;
              });
            },
          );
        },
      ),
    );
  }

  // =========================================================
  // ANIME GRID
  // =========================================================

  Widget _buildAnimeGrid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> animeList,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth;

        if (constraints.maxWidth >= 1200) {
          cardWidth = 210;
        } else if (constraints.maxWidth >= 800) {
          cardWidth = 190;
        } else if (constraints.maxWidth >= 500) {
          cardWidth = 160;
        } else {
          cardWidth = 140;
        }

        return GridView.builder(
          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          itemCount: animeList.length,

          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: cardWidth,

            mainAxisExtent: 330,

            crossAxisSpacing: 18,

            mainAxisSpacing: 25,
          ),

          itemBuilder: (context, index) {
            final doc = animeList[index];

            final data = doc.data();

            return _buildAnimeCard(doc.id, data);
          },
        );
      },
    );
  }

  // =========================================================
  // ANIME CARD
  // =========================================================

  Widget _buildAnimeCard(String id, Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'ไม่มีชื่อ';

    final imageUrl = data['imageUrl']?.toString() ?? '';

    final category = data['category']?.toString() ?? '';

    final type = data['type']?.toString() ?? '';

    final rating = data['rating']?.toString() ?? '0';

    final latestEpisode = data['latestEpisode']?.toString() ?? '1';

    return InkWell(
      borderRadius: BorderRadius.circular(10),

      // =================================================
      // กดการ์ด → หน้า Detail
      // =================================================
      onTap: () {
        _openAnimeDetail(id, data);
      },

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =============================================
          // POSTER
          // =============================================

          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),

                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),

                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,

                            fit: BoxFit.cover,

                            errorBuilder: (context, error, stackTrace) {
                              return _imageError();
                            },
                          )
                        : _imageError(),
                  ),
                ),

                // =========================================
                // TYPE
                // =========================================
                Positioned(
                  top: 8,
                  left: 8,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.red,

                      borderRadius: BorderRadius.circular(5),
                    ),

                    child: Text(
                      type.isEmpty ? 'ANIME' : type,

                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // =========================================
                // RATING
                // =========================================
                Positioned(
                  bottom: 8,
                  right: 8,

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),

                      borderRadius: BorderRadius.circular(5),
                    ),

                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 15),

                        const SizedBox(width: 3),

                        Text(
                          rating,

                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =========================================
                // PLAY ICON
                // =========================================
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),

                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // =============================================
          // TITLE
          // =============================================
          Text(
            title,

            maxLines: 1,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          // =============================================
          // CATEGORY + EPISODE
          // =============================================
          Row(
            children: [
              Expanded(
                child: Text(
                  category.isEmpty ? 'ไม่ระบุหมวดหมู่' : category,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),

              Text(
                'EP.$latestEpisode',

                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // IMAGE ERROR
  // =========================================================

  Widget _imageError() {
    return Container(
      color: const Color(0xFF151515),

      child: const Center(
        child: Icon(Icons.movie_outlined, size: 55, color: Colors.grey),
      ),
    );
  }

  // =========================================================
  // EMPTY DATABASE
  // =========================================================

  Widget _buildEmptyDatabase() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.movie_filter_outlined,
              size: 90,
              color: Colors.grey,
            ),

            const SizedBox(height: 20),

            const Text(
              'ยังไม่มีข้อมูล Anime',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'กรุณาเพิ่มข้อมูล Anime ใน Firebase Firestore',
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            ElevatedButton(
              onPressed: () {
                setState(() {});
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,

                foregroundColor: Colors.white,
              ),

              child: const Text('รีเฟรช'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NO SEARCH RESULT
  // =========================================================

  Widget _buildNoSearchResult() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(50),

      child: const Column(
        children: [
          Icon(Icons.search_off, size: 70, color: Colors.grey),

          SizedBox(height: 15),

          Text(
            'ไม่พบอนิเมะที่ค้นหา',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
