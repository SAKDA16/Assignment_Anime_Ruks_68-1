import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/episode_model.dart';

class EpisodeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> episodes(String animeId) {
    return _firestore.collection('anime').doc(animeId).collection('episodes');
  }

  // =========================
  // Get Episodes
  // =========================

  Stream<List<EpisodeModel>> getEpisodes(String animeId) {
    return episodes(animeId).orderBy('episode').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return EpisodeModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // =========================
  // Add Episode
  // =========================

  Future<void> addEpisode(String animeId, Map<String, dynamic> data) async {
    await episodes(animeId).add(data);
  }

  // =========================
  // Update Episode
  // =========================

  Future<void> updateEpisode(
    String animeId,
    String episodeId,
    Map<String, dynamic> data,
  ) async {
    await episodes(animeId).doc(episodeId).update(data);
  }

  // =========================
  // Delete Episode
  // =========================

  Future<void> deleteEpisode(String animeId, String episodeId) async {
    await episodes(animeId).doc(episodeId).delete();
  }
}
