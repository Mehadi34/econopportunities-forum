import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  const StorageService();

  Future<String?> uploadProfilePhoto(File file, String userId) async {
    try {
      final ext = path.extension(file.path);
      final ref = _storage.ref('profile_photos/$userId$ext');
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadEventImage(File file, String eventId) async {
    try {
      final ext = path.extension(file.path);
      final ref = _storage.ref('event_images/$eventId$ext');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadResource(
      File file, String category) async {
    try {
      const uuid = Uuid();
      final fileName = path.basename(file.path);
      final fileId = uuid.v4();
      final ref = _storage.ref('resources/$category/$fileId/$fileName');

      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      final metadata = await uploadTask.ref.getMetadata();

      return {
        'fileUrl': url,
        'fileName': fileName,
        'fileSize': metadata.size,
      };
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadAnnouncementImage(File file) async {
    try {
      const uuid = Uuid();
      final ext = path.extension(file.path);
      final ref = _storage.ref('announcements/${uuid.v4()}$ext');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadPostImage(File file) async {
    try {
      const uuid = Uuid();
      final ext = path.extension(file.path);
      final ref = _storage.ref('post_images/${uuid.v4()}$ext');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
