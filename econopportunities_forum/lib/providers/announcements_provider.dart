import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart';

final announcementsProvider = StreamProvider<List<AnnouncementModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAnnouncementsStream();
});

final allAnnouncementsAdminProvider =
    StreamProvider<List<AnnouncementModel>>((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .getAnnouncementsStream(publishedOnly: false);
});
