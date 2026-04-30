import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/members_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/user_avatar.dart';

class MemberProfileScreen extends ConsumerWidget {
  final String uid;
  const MemberProfileScreen({super.key, required this.uid});

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.error;
      case UserRole.moderator:
        return AppColors.warning;
      case UserRole.member:
        return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(memberProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Member not found'));
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                _ProfileHeader(member: member, roleColor: _roleColor(member.role)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (member.bio != null && member.bio!.isNotEmpty)
                        _Section(
                          title: 'About',
                          child: Text(member.bio!,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      _InfoCard(member: member),
                      if (member.skills.isNotEmpty)
                        _ChipsSection(
                            title: 'Skills', chips: member.skills),
                      if (member.interests.isNotEmpty)
                        _ChipsSection(
                            title: 'Interests', chips: member.interests),
                      if (member.achievements.isNotEmpty)
                        _AchievementsSection(
                            achievements: member.achievements),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel member;
  final Color roleColor;
  const _ProfileHeader(
      {required this.member, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          UserAvatar(
            photoUrl: member.photoUrl,
            displayName: member.displayName,
            radius: 48,
            showBorder: true,
          ),
          const SizedBox(height: 12),
          Text(
            member.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.email,
            style:
                TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor, width: 1.5),
            ),
            child: Text(
              member.roleDisplayName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final UserModel member;
  const _InfoCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Information',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (member.department != null)
              _InfoRow(
                  icon: Icons.business, label: 'Department',
                  value: member.department!),
            if (member.year != null)
              _InfoRow(
                  icon: Icons.school, label: 'Year', value: member.year!),
            if (member.phone != null)
              _InfoRow(
                  icon: Icons.phone, label: 'Phone', value: member.phone!),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChipsSection extends StatelessWidget {
  final String title;
  final List<String> chips;
  const _ChipsSection({required this.title, required this.chips});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: title,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips
            .map((s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primary),
                  visualDensity: VisualDensity.compact,
                ))
            .toList(),
      ),
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final List<String> achievements;
  const _AchievementsSection({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Achievements',
      child: Column(
        children: achievements
            .map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
