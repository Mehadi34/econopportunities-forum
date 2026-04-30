import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(firestoreServiceProvider).getAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _StatsGrid(data: data),
                const SizedBox(height: 24),
                Text(
                  'Content Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _ContentBreakdown(data: data),
                const SizedBox(height: 24),
                Text(
                  'User Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _UserActivity(data: data),
                const SizedBox(height: 24),
                Text(
                  'Popular Categories',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _PopularCategories(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.people, 'Users', '${data['totalUsers'] ?? 0}', AppColors.primary),
      (Icons.event, 'Events', '${data['totalEvents'] ?? 0}', AppColors.secondary),
      (Icons.forum, 'Posts', '${data['totalPosts'] ?? 0}', AppColors.accent),
      (Icons.campaign, 'Announcements', '${data['totalAnnouncements'] ?? 0}',
          AppColors.warning),
      (Icons.folder, 'Resources', '${data['totalResources'] ?? 0}',
          AppColors.success),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final (icon, label, value, color) = stats[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const Spacer(),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContentBreakdown extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ContentBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Active Users', data['activeUsers'] ?? 0, AppColors.success),
      ('Published Events', data['publishedEvents'] ?? 0, AppColors.primary),
      ('Approved Posts', data['approvedPosts'] ?? 0, AppColors.accent),
      ('Published Announcements', data['publishedAnnouncements'] ?? 0,
          AppColors.warning),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.$3,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item.$1,
                            style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                        '${item.$2}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.$3,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _UserActivity extends StatelessWidget {
  final Map<String, dynamic> data;
  const _UserActivity({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalUsers = (data['totalUsers'] as int?) ?? 1;
    final activeUsers = (data['activeUsers'] as int?) ?? 0;
    final activityRate = totalUsers > 0 ? activeUsers / totalUsers : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Users',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '$activeUsers / $totalUsers',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: activityRate.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(activityRate * 100).toStringAsFixed(1)}% activity rate',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularCategories extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Economics', 0.85, AppColors.primary),
      ('Opportunities', 0.72, AppColors.secondary),
      ('General', 0.65, AppColors.accent),
      ('Help & Questions', 0.45, AppColors.warning),
      ('Projects', 0.38, AppColors.success),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: categories
              .map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat.$1,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            '${(cat.$2 * 100).toInt()}%',
                            style: TextStyle(
                                color: cat.$3,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: cat.$2,
                          minHeight: 8,
                          backgroundColor: AppColors.divider,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(cat.$3),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
