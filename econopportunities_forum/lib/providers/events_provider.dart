import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final eventsProvider = StreamProvider.family<List<EventModel>, EventStatus?>(
    (ref, status) {
  return ref.watch(firestoreServiceProvider).getEventsStream(status: status);
});

final allEventsProvider = StreamProvider<List<EventModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getEventsStream();
});

final eventDetailProvider =
    StreamProvider.family<EventModel?, String>((ref, id) {
  return ref.watch(firestoreServiceProvider).getEventStream(id);
});

final userRegisteredEventsProvider = StreamProvider<List<EventModel>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  if (userId == null) return Stream.value([]);

  return ref
      .watch(firestoreServiceProvider)
      .getEventsStream()
      .map((events) => events.where((e) => e.isUserRegistered(userId)).toList());
});
