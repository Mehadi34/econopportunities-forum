import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/events_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isLoading = false;

  Future<void> _toggleRegistration(
      EventModel event, String userId, bool isRegistered) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      if (isRegistered) {
        await service.unregisterFromEvent(widget.eventId, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unregistered from event')),
          );
        }
      } else {
        await service.registerForEvent(widget.eventId, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registered for event!')),
          );
        }
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
        content: const Text(
            'Are you sure you want to delete this event? This cannot be undone.'),
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
      await ref.read(firestoreServiceProvider).deleteEvent(widget.eventId);
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
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final isModerator = ref.watch(isModeratorProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        body: eventAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (event) {
            if (event == null) {
              return const Center(child: Text('Event not found'));
            }
            final isRegistered = currentUser != null &&
                event.isUserRegistered(currentUser.uid);
            final isFull = event.isFull && !isRegistered;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      event.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    background: event.imageUrl != null
                        ? Image.network(event.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _GradientHeader(event: event))
                        : _GradientHeader(event: event),
                  ),
                  actions: isModerator
                      ? [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                context.push('/events/${widget.eventId}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: _deleteEvent,
                          ),
                        ]
                      : null,
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _InfoSection(event: event),
                      const SizedBox(height: 16),
                      _DescriptionSection(event: event),
                      const SizedBox(height: 16),
                      if (event.meetingLink != null &&
                          event.meetingLink!.isNotEmpty)
                        _MeetingLinkCard(link: event.meetingLink!),
                      const SizedBox(height: 16),
                      _AttendeesCard(event: event),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: eventAsync.valueOrNull != null && currentUser != null
            ? Builder(builder: (context) {
                final event = eventAsync.value!;
                final isRegistered = event.isUserRegistered(currentUser.uid);
                final isFull = event.isFull && !isRegistered;
                return FloatingActionButton.extended(
                  onPressed: (event.status == EventStatus.cancelled ||
                          event.status == EventStatus.completed ||
                          isFull)
                      ? null
                      : () => _toggleRegistration(
                          event, currentUser.uid, isRegistered),
                  backgroundColor:
                      isRegistered ? AppColors.error : AppColors.success,
                  label: Text(
                    isRegistered
                        ? 'Unregister'
                        : isFull
                            ? 'Event Full'
                            : 'Register',
                  ),
                  icon: Icon(isRegistered ? Icons.cancel : Icons.check_circle),
                );
              })
            : null,
      ),
    );
  }
}

class _GradientHeader extends StatelessWidget {
  final EventModel event;
  const _GradientHeader({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(event.category),
          size: 80,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }

  IconData _categoryIcon(EventCategory cat) {
    switch (cat) {
      case EventCategory.workshop:
        return Icons.build;
      case EventCategory.seminar:
        return Icons.school;
      case EventCategory.networking:
        return Icons.people;
      case EventCategory.competition:
        return Icons.emoji_events;
      case EventCategory.social:
        return Icons.celebration;
      case EventCategory.other:
        return Icons.event;
    }
  }
}

class _InfoSection extends StatelessWidget {
  final EventModel event;
  const _InfoSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Start',
              value: DateFormat('MMM d, yyyy HH:mm').format(event.startDateTime),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'End',
              value: DateFormat('MMM d, yyyy HH:mm').format(event.endDateTime),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: event.location,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.category,
              label: 'Category',
              value: event.categoryDisplayName,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.person,
              label: 'Organizer',
              value: event.createdByName,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final EventModel event;
  const _DescriptionSection({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About This Event',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(event.description,
                style: Theme.of(context).textTheme.bodyMedium),
            if (event.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: event.tags
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MeetingLinkCard extends StatelessWidget {
  final String link;
  const _MeetingLinkCard({required this.link});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.videocam, color: AppColors.primary),
        title: const Text('Meeting Link'),
        subtitle: Text(link,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.info)),
        trailing: const Icon(Icons.open_in_new),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening link...')),
          );
        },
      ),
    );
  }
}

class _AttendeesCard extends StatelessWidget {
  final EventModel event;
  const _AttendeesCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.people, color: AppColors.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Registered Attendees',
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  event.maxAttendees > 0
                      ? '${event.attendeeCount} / ${event.maxAttendees}'
                      : '${event.attendeeCount} registered',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: event.isFull
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            if (event.maxAttendees > 0) ...[
              const Spacer(),
              CircularProgressIndicator(
                value: event.attendeeCount / event.maxAttendees,
                backgroundColor: AppColors.divider,
                color: event.isFull ? AppColors.error : AppColors.success,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
