import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

final membersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .getUsersStream(isActive: true);
});

final memberProfileProvider =
    StreamProvider.family<UserModel?, String>((ref, uid) {
  return ref.watch(firestoreServiceProvider).getUserStream(uid);
});

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedDepartmentProvider = StateProvider<String?>((ref) => null);
final selectedRoleProvider = StateProvider<UserRole?>((ref) => null);

final filteredMembersProvider = StreamProvider<List<UserModel>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider);
  final department = ref.watch(selectedDepartmentProvider);
  final role = ref.watch(selectedRoleProvider);

  return ref.watch(firestoreServiceProvider).getUsersStream(
        role: role,
        isActive: true,
        searchQuery: searchQuery.isNotEmpty ? searchQuery : null,
      );
});
