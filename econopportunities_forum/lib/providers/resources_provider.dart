import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/resource_model.dart';
import '../services/firestore_service.dart';

final resourcesProvider =
    StreamProvider.family<List<ResourceModel>, ResourceCategory?>((ref, category) {
  return ref
      .watch(firestoreServiceProvider)
      .getResourcesStream(category: category);
});

final allResourcesProvider = StreamProvider<List<ResourceModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getResourcesStream();
});
