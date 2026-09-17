import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/anime_model.dart';

class AnimeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _animeCollection =>
      _firestore.collection('anime');

  // =========================
  // Get Anime
  // =========================

  Stream<List<AnimeModel>> getAnimeStream() {
    return _animeCollection.orderBy('title').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return AnimeModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // =========================
  // Add Anime
  // =========================

  Future<void> addAnime(Map<String, dynamic> data) async {
    await _animeCollection.add(data);
  }

  // =========================
  // Update Anime
  // =========================

  Future<void> updateAnime(String id, Map<String, dynamic> data) async {
    await _animeCollection.doc(id).update(data);
  }

  // =========================
  // Delete Anime
  // =========================

  Future<void> deleteAnime(String id) async {
    await _animeCollection.doc(id).delete();
  }

  // =========================
  // Get One Anime
  // =========================

  Future<AnimeModel?> getAnime(String id) async {
    final doc = await _animeCollection.doc(id).get();

    if (!doc.exists) {
      return null;
    }

    return AnimeModel.fromMap(doc.id, doc.data()!);
  }
}
