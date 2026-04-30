import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/events_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_overlay.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  EventCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isModerator = ref.watch(isModeratorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search events...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'All Events'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'My Events'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<EventCategory?>(
            icon: Icon(
              Icons.filter_list,
              color: _selectedCategory != null ? Colors.amber : Colors.white,
            ),
            tooltip: 'Filter by category',
            onSelected: (cat) => setState(() => _selectedCategory = cat),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Categories')),
              ...EventCategory.values.map(
                (c) => PopupMenuItem(
                  value: c,
                  child: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EventsList(
            eventsAsync: ref.watch(allEventsProvider),
            searchQuery: _searchQuery,
            category: _selectedCategory,
          ),
          _EventsList(
            eventsAsync: ref.watch(eventsProvider(EventStatus.upcoming)),
            searchQuery: _searchQuery,
            category: _selectedCategory,
          ),
          _EventsList(
            eventsAsync: ref.watch(userRegisteredEventsProvider),
            searchQuery: _searchQuery,
            category: _selectedCategory,
            emptyMessage: 'No registered events',
          ),
        ],
      ),
      floatingActionButton: isModerator
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/events/create'),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            )
          : null,
    );
  }
}

class _EventsList extends ConsumerWidget {
  final AsyncValue<List<EventModel>> eventsAsync;
  final String searchQuery;
  final EventCategory? category;
  final String emptyMessage;

  const _EventsList({
    required this.eventsAsync,
    required this.searchQuery,
    required this.category,
    this.emptyMessage = 'No events found',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(message: e.toString()),
      data: (events) {
        var filtered = events;
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          filtered = filtered
              .where((e) =>
                  e.title.toLowerCase().contains(q) ||
                  e.description.toLowerCase().contains(q) ||
                  e.location.toLowerCase().contains(q))
              .toList();
        }
        if (category != null) {
          filtered = filtered.where((e) => e.category == category).toList();
        }

        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.event_outlined,
            title: emptyMessage,
            subtitle: 'Check back later for upcoming events',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _EventCard(event: filtered[i]),
          ),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/events/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    event.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              if (event.imageUrl != null) const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    label: Text(event.categoryDisplayName),
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  _StatusChip(status: event.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy HH:mm').format(event.startDateTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.people,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${event.attendeeCount}${event.maxAttendees > 0 ? '/${event.maxAttendees}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final EventStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case EventStatus.upcoming:
        return AppColors.info;
      case EventStatus.ongoing:
        return AppColors.success;
      case EventStatus.completed:
        return AppColors.textSecondary;
      case EventStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
