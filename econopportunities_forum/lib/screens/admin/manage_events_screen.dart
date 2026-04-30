import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';

final _allEventsAdminProvider = StreamProvider<List<EventModel>>((ref) {
  return ref
      .watch(firestoreServiceProvider)
      .getEventsStream(publishedOnly: false);
});

class ManageEventsScreen extends ConsumerWidget {
  const ManageEventsScreen({super.key});

  Future<void> _deleteEvent(
      BuildContext context, WidgetRef ref, String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Delete this event? This cannot be undone.'),
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
    try {
      await ref.read(firestoreServiceProvider).deleteEvent(eventId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Event deleted')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _togglePublish(
      BuildContext context, WidgetRef ref, EventModel event) async {
    try {
      await ref.read(firestoreServiceProvider).updateEvent(event.id, {
        'isPublished': !event.isPublished,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(event.isPublished
                  ? 'Event unpublished'
                  : 'Event published')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(_allEventsAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/events/create'),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (events) {
          if (events.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.event_outlined,
              title: 'No events yet',
              actionLabel: 'Create Event',
              onAction: () => context.push('/events/create'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (_, i) => _AdminEventCard(
              event: events[i],
              onEdit: () =>
                  context.push('/events/${events[i].id}/edit'),
              onDelete: () =>
                  _deleteEvent(context, ref, events[i].id),
              onTogglePublish: () =>
                  _togglePublish(context, ref, events[i]),
            ),
          );
        },
      ),
    );
  }
}

class _AdminEventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublish;

  const _AdminEventCard({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.isPublished
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.isPublished ? 'Published' : 'Draft',
                    style: TextStyle(
                      color: event.isPublished
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, yyyy HH:mm').format(event.startDateTime),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            Text(
              event.location,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(
                  label: Text(event.categoryDisplayName,
                      style: const TextStyle(fontSize: 10)),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primary),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(
                    event.isPublished
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 16,
                  ),
                  label: Text(event.isPublished ? 'Unpublish' : 'Publish',
                      style: const TextStyle(fontSize: 12)),
                  onPressed: onTogglePublish,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete,
                      size: 18, color: AppColors.error),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
