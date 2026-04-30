import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final notificationsProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getNotificationsStream(userId);
});

final unreadNotificationCountProvider = StreamProvider<int>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return Stream.value(0);
  return ref
      .watch(firestoreServiceProvider)
      .getUnreadNotificationCount(userId);
});
