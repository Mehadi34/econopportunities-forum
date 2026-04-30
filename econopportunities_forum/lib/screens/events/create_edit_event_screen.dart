import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';

class CreateEditEventScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const CreateEditEventScreen({super.key, this.eventId});

  @override
  ConsumerState<CreateEditEventScreen> createState() =>
      _CreateEditEventScreenState();
}

class _CreateEditEventScreenState
    extends ConsumerState<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _meetingLinkController = TextEditingController();

  EventCategory _category = EventCategory.other;
  DateTime _startDateTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endDateTime = DateTime.now().add(const Duration(days: 1, hours: 2));
  bool _isPublished = true;
  bool _isLoading = false;
  File? _imageFile;
  String? _existingImageUrl;
  EventModel? _existingEvent;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final event =
          await ref.read(firestoreServiceProvider).getEvent(widget.eventId!);
      if (event != null && mounted) {
        setState(() {
          _existingEvent = event;
          _titleController.text = event.title;
          _descriptionController.text = event.description;
          _locationController.text = event.location;
          _maxAttendeesController.text =
              event.maxAttendees > 0 ? event.maxAttendees.toString() : '';
          _meetingLinkController.text = event.meetingLink ?? '';
          _category = event.category;
          _startDateTime = event.startDateTime;
          _endDateTime = event.endDateTime;
          _isPublished = event.isPublished;
          _existingImageUrl = event.imageUrl;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxAttendeesController.dispose();
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickStartDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickEndDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDateTime.isAfter(_startDateTime)
          ? _endDateTime
          : _startDateTime,
      firstDate: _startDateTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDateTime),
    );
    if (time == null || !mounted) return;
    setState(() {
      _endDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDateTime.isBefore(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = ref.read(currentUserProvider).valueOrNull;
      final firestore = ref.read(firestoreServiceProvider);
      const storage = StorageService();

      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        final id = widget.eventId ?? DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await storage.uploadEventImage(_imageFile!, id);
      }

      final maxAttendees = int.tryParse(_maxAttendeesController.text) ?? 0;

      if (widget.eventId == null) {
        final event = EventModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim(),
          startDateTime: _startDateTime,
          endDateTime: _endDateTime,
          createdBy: currentUser?.uid ?? '',
          createdByName: currentUser?.displayName ?? '',
          category: _category,
          maxAttendees: maxAttendees,
          meetingLink: _meetingLinkController.text.trim().isEmpty
              ? null
              : _meetingLinkController.text.trim(),
          imageUrl: imageUrl,
          isPublished: _isPublished,
          createdAt: DateTime.now(),
        );
        await firestore.createEvent(event);
      } else {
        await firestore.updateEvent(widget.eventId!, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'startDateTime': _startDateTime.toIso8601String(),
          'endDateTime': _endDateTime.toIso8601String(),
          'category': _category.name,
          'maxAttendees': maxAttendees,
          'meetingLink': _meetingLinkController.text.trim().isEmpty
              ? null
              : _meetingLinkController.text.trim(),
          'imageUrl': imageUrl,
          'isPublished': _isPublished,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.eventId == null
                  ? 'Event created!'
                  : 'Event updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(firestoreServiceProvider).deleteEvent(widget.eventId!);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
          actions: [
            if (widget.eventId != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteEvent,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ImagePicker(
                imageFile: _imageFile,
                existingUrl: _existingImageUrl,
                onPick: _pickImage,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EventCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: EventCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name[0].toUpperCase() +
                              c.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Location required' : null,
              ),
              const SizedBox(height: 12),
              _DateTimeTile(
                label: 'Start Date & Time',
                dateTime: _startDateTime,
                onTap: _pickStartDateTime,
              ),
              const SizedBox(height: 8),
              _DateTimeTile(
                label: 'End Date & Time',
                dateTime: _endDateTime,
                onTap: _pickEndDateTime,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _maxAttendeesController,
                decoration: const InputDecoration(
                  labelText: 'Max Attendees (0 = unlimited)',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _meetingLinkController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Link (optional)',
                  prefixIcon: Icon(Icons.videocam),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Published'),
                subtitle: const Text('Make event visible to members'),
                value: _isPublished,
                onChanged: (v) => setState(() => _isPublished = v),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(
                    widget.eventId == null ? 'Create Event' : 'Update Event'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  final File? imageFile;
  final String? existingUrl;
  final VoidCallback onPick;

  const _ImagePicker({
    required this.imageFile,
    required this.existingUrl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile!, fit: BoxFit.cover,
                    width: double.infinity),
              )
            : existingUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(existingUrl!, fit: BoxFit.cover,
                        width: double.infinity),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('Tap to add event banner',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.label,
    required this.dateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      tileColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.access_time, color: AppColors.primary),
      title: Text(label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      subtitle: Text(
        DateFormat('MMM d, yyyy HH:mm').format(dateTime),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.edit_calendar),
      onTap: onTap,
    );
  }
}
