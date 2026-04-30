import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/announcement_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _linkController = TextEditingController();
  final _linkTextController = TextEditingController();

  bool _isImportant = false;
  bool _isPublished = true;
  File? _imageFile;
  DateTime? _expiresAt;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _linkController.dispose();
    _linkTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() => _expiresAt = date);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      if (currentUser == null) throw Exception('Not logged in');
      const storage = StorageService();

      String? imageUrl;
      if (_imageFile != null) {
        final result =
            await storage.uploadResource(_imageFile!, 'announcements');
        imageUrl = result?['fileUrl'];
      }

      final announcement = AnnouncementModel(
        id: '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: currentUser.uid,
        authorName: currentUser.displayName,
        imageUrl: imageUrl,
        isImportant: _isImportant,
        isPublished: _isPublished,
        link: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
        linkText: _linkTextController.text.trim().isEmpty
            ? null
            : _linkTextController.text.trim(),
        expiresAt: _expiresAt,
        createdAt: DateTime.now(),
      );

      await ref
          .read(firestoreServiceProvider)
          .createAnnouncement(announcement);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement created!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Announcement')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _imageFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_imageFile!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                              onPressed: () =>
                                  setState(() => _imageFile = null),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ],
                    )
                  : OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Image (optional)'),
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  prefixIcon: Icon(Icons.text_fields),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                minLines: 4,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Content required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link (optional)',
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkTextController,
                decoration: const InputDecoration(
                  labelText: 'Link Button Text (optional)',
                  prefixIcon: Icon(Icons.label),
                  hintText: 'e.g. Learn More',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                tileColor: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.timer_outlined,
                    color: AppColors.primary),
                title: const Text('Expires At'),
                subtitle: Text(
                  _expiresAt != null
                      ? DateFormat('MMM d, yyyy').format(_expiresAt!)
                      : 'No expiry set',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: _expiresAt != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expiresAt = null),
                      )
                    : const Icon(Icons.calendar_today),
                onTap: _pickExpiryDate,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Important'),
                subtitle: const Text('Highlight this announcement'),
                value: _isImportant,
                activeColor: AppColors.warning,
                onChanged: (v) => setState(() => _isImportant = v),
              ),
              SwitchListTile(
                title: const Text('Published'),
                subtitle: const Text('Make visible to members immediately'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Create Announcement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
